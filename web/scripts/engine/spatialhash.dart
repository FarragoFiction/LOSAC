import "dart:math";

import "../level/levelobject.dart";

class SpatialHash {
	final double bucketSize;
	final int xPos;
	final int yPos;
	final int xSize;
	final int ySize;

	Map<SpatialHashable, Rectangle<num>> objects;
	Map<SpatialHashKey, Set<SpatialHashable>> _map;
	
	SpatialHash(double this.bucketSize, num xPos, num yPos, num xSize, num ySize) : this.xPos = xPos.floor(), this.yPos = yPos.floor(), this.xSize = xSize.ceil(), this.ySize = ySize.ceil() {
		this.clear();
	}
	
	void clear() {
		this.objects = <SpatialHashable, Rectangle<num>>{};
		this._map = <SpatialHashKey, Set<SpatialHashable>>{};
	}
	
	void insert(SpatialHashable col) {
		if (col.spatialHash == null || col.spatialHash == this) {
			final Rectangle<num> bounds = col.bounds;
			
			if (col.spatialHash == this) {
				final Rectangle<num> oldBounds = this.objects[col];
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

		final int minX = (bounds.left   / this.bucketSize).floor() - xPos;
		final int maxX = (bounds.right  / this.bucketSize).floor() - xPos;
		final int minY = (bounds.top    / this.bucketSize).floor() - yPos;
		final int maxY = (bounds.bottom / this.bucketSize).floor() - yPos;

		for (int x = minX; x <= maxX; x++) {
			for (int y = minY; y <= maxY; y++) {
				final SpatialHashKey key = new SpatialHashKey(this, x,y);
                keys.add(key);
			}
		}
		
		return keys;
	}
	
	void remove(SpatialHashable col) {
		for (final SpatialHashKey key in col.spatialBuckets) {
			this.removeFromBucket(key, col);
		}
		this.objects.remove(col);
		
		col.spatialBuckets = null;
		col.spatialHash = null;
	}
	
	void addToBucket(SpatialHashKey key, SpatialHashable val) {
		if (!_map.containsKey(key)) {
			_map[key] = <SpatialHashable>{};
		}
		_map[key].add(val);
	}
	
	void removeFromBucket(SpatialHashKey key, SpatialHashable val) {
		_map[key].remove(val);
		if (_map[key].isEmpty) {
			_map.remove(key);
		}
	}
	
	Set<SpatialHashable> query(SpatialHashable test) {
		if (test.spatialHash != this) { return null; }
		final Set<SpatialHashable> collided = <SpatialHashable>{};
		
		for (final SpatialHashKey key in test.spatialBuckets) {
			if (_map.containsKey(key)) {
				collided.addAll(_map[key]);
			}
		}
		
		return collided;
	}
	
	Set<SpatialHashable> queryRect(Rectangle<num> bounds) {
		final Set<SpatialHashable> collided = <SpatialHashable>{};
		
		final Set<SpatialHashKey> keys = this.getKeysForRect(bounds);
		
		for (final SpatialHashKey key in keys) {
			if (_map.containsKey(key)) {
				collided.addAll(this._map[key]);
			}
		}
		
		return collided;
	}

	Set<SpatialHashable> queryRadius(num x, num y, num radius) {
		final Rectangle<num> rect = new Rectangle<num>(x - radius, y - radius, radius*2, radius*2);

		final Set<SpatialHashable> collided = <SpatialHashable>{};
		final Set<SpatialHashKey> keys = this.getKeysForRect(rect);

		for (final SpatialHashKey key in keys) {
			if (_map.containsKey(key)) {
				final Set<SpatialHashable> objects = this._map[key];
				for(final SpatialHashable object in objects) {
					final double dx = object.pos_x - x;
					final double dy = object.pos_y - y;
					final double distSquared = dx*dx + dy*dy;

					if (distSquared <= radius) {
						collided.add(object);
					}
				}
			}
		}

		return collided;
	}
}

class SpatialHashKey {
	final int x;
	final int y;

	int _hash;

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
}

mixin SpatialHashable on LevelObject {
	SpatialHash spatialHash;
	Set<SpatialHashKey> spatialBuckets;
}