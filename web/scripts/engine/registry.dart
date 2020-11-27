
class Registry<T extends Registerable> {
    final Map<String, T> mapping = <String,T>{};

    void register(T item) {
        final String key = item.getRegistrationKey();

        if (mapping.containsKey(key)) {
            throw Exception("Cannot register $key, key already exists!");
        }

        mapping[key] = item;
    }

    T get(String key) {
        if (!mapping.containsKey(key)) { return null; }

        return mapping[key];
    }

    Iterable<MapEntry<String,T>> getAll(Iterable<String> keys) {
        final Set<String> keySet = keys is Set<String> ? keys : keys.toSet();
        return mapping.entries.where((MapEntry<String,T> e) => keySet.contains(e.key));
    }

    Iterable<T> getAllValues(Iterable<String> keys) {
        final Set<String> keySet = keys is Set<String> ? keys : keys.toSet();
        return mapping.keys.where(keySet.contains).map(get);
    }

    Iterable<MapEntry<String,T>> where(bool Function(MapEntry<String,T> tested) test) {
        return mapping.entries.where(test);
    }

    Iterable<T> whereValue(bool Function(T tested) test) {
        return mapping.values.where(test);
    }
}

mixin Registerable {
    String getRegistrationKey();
}