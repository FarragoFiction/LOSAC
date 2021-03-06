import "dart:math";

import "package:CubeLib/CubeLib.dart" as B;

import "../level/levelobject.dart";

// ignore: always_specify_types
class SpatialHash<T extends SpatialHashable> {
	final double bucketSize;
	final int xPos;
	final int yPos;
	final int xSize;
	final int ySize;

	late Map<T, Rectangle<num>> objects;
	late Map<SpatialHashKey, Set<T>> buckets;

	int get length => objects.length;
	
	SpatialHash(double this.bucketSize, num xPos, num yPos, num xSize, num ySize) : this.xPos = xPos.floor(), this.yPos = yPos.floor(), this.xSize = xSize.ceil(), this.ySize = ySize.ceil() {
		this.clear();
	}
	
	void clear() {
		this.objects = <T, Rectangle<num>>{};
		this.buckets = <SpatialHashKey, Set<T>>{};
	}
	
	void insert(T col) {
		if (col.spatialHash == null || col.spatialHash == this) {
			final Rectangle<num> bounds = col.bounds;

			if (col.spatialHash == this) {
				final Rectangle<num> oldBounds = this.objects[col]!; // if the hash is this, we can assume objects contains it
				if (bounds == oldBounds) {
					return; // object is already in and is in the same place it was before
				} else {
					this.remove(col); // remove the object in preparation for re-adding
				}
			}
			
			col.spatialHash = this;

			final Set<SpatialHashKey> keys = this.getKeysForRect(bounds);
			for (final SpatialHashKey k in keys) {
				this.addToBucket(k, col);
			}
			
			col.spatialBuckets = keys;
			this.objects[col] = bounds;
		} else {
			// error because can't be in more than one
		}
	}
	
	Set<SpatialHashKey> getKeysForRect(Rectangle<num> bounds) {
		final Set<SpatialHashKey> keys = <SpatialHashKey>{};

		final int minX = ((bounds.left   - xPos) / this.bucketSize).floor();
		final int maxX = ((bounds.right  - xPos) / this.bucketSize).floor();
		final int minY = ((bounds.top    - yPos) / this.bucketSize).floor();
		final int maxY = ((bounds.bottom - yPos) / this.bucketSize).floor();

		for (int x = minX; x <= maxX; x++) {
			for (int y = minY; y <= maxY; y++) {
				final SpatialHashKey key = new SpatialHashKey(this, x,y);
                keys.add(key);
			}
		}
		
		return keys;
	}
	
	void remove(T col) {
		for (final SpatialHashKey key in col.spatialBuckets!) {
			this.removeFromBucket(key, col);
		}
		this.objects.remove(col);
		
		col.spatialBuckets = null;
		col.spatialHash = null;
	}
	
	void addToBucket(SpatialHashKey key, T val) {
		if (!buckets.containsKey(key)) {
			buckets[key] = <T>{};
		}
		buckets[key]!.add(val);
	}
	
	void removeFromBucket(SpatialHashKey key, T val) {
		final Set<T> bucket = buckets[key]!; // this is only called when the bucket exists
		bucket.remove(val);
		if (bucket.isEmpty) {
			buckets.remove(key);
		}
	}
	
	Set<T>? query(T test) {
		if (test.spatialHash != this || test.spatialBuckets == null) { return null; }
		final Set<T> collided = <T>{};
		
		for (final SpatialHashKey key in test.spatialBuckets!) {
			if (buckets.containsKey(key)) {
				collided.addAll(buckets[key]!);
			}
		}
		
		return collided;
	}
	
	Set<T> queryRect(Rectangle<num> bounds) {
		final Set<T> collided = <T>{};
		
		final Set<SpatialHashKey> keys = this.getKeysForRect(bounds);
		
		for (final SpatialHashKey key in keys) {
			if (buckets.containsKey(key)) {
				collided.addAll(this.buckets[key]!);
			}
		}
		
		return collided;
	}

	Set<T> queryRadius(num x, num y, num radius) {
		final Rectangle<num> rect = new Rectangle<num>(x - radius, y - radius, radius*2, radius*2);
		final num rSquared = radius * radius;

		final Set<T> collided = <T>{};
		final Set<SpatialHashKey> keys = this.getKeysForRect(rect);

		for (final SpatialHashKey key in keys) {
			if (buckets.containsKey(key)) {
				final Set<T> objects = this.buckets[key]!;
				for(final T object in objects) {
					final B.Vector2 pos = object.getWorldPosition();
					final num dx = pos.x - x;
					final num dy = pos.y - y;
					final num distSquared = dx*dx + dy*dy;

					if (distSquared <= rSquared) {
						collided.add(object);
					}
				}
				//collided.addAll(this.buckets[key]);
			}
		}

		return collided;
	}
}

class SpatialHashKey {
	final int x;
	final int y;

	late int _hash;

	// ignore: always_specify_types
	SpatialHashKey(SpatialHash sh, int this.x, int this.y) {
		final int xh = x + sh.xSize + 31;
		final int yh = y + sh.ySize + 37;

		this._hash = yh + (yh * 43) * (xh+(xh * 47));
	}

	@override
	int get hashCode => _hash;

	@override
	bool operator ==(dynamic other) {
		return (other is SpatialHashKey) && other._hash == this._hash;
	}

	@override
	String toString() => "($x,$y)";
}

mixin SpatialHashable<T> on LevelObject {
	// ignore: always_specify_types
	SpatialHash? spatialHash;
	Set<SpatialHashKey>? spatialBuckets;
}