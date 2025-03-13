import 'package:objectbox/objectbox.dart';

/// Base repository class for entity models
/// Contains common methods used by repositories like CurrencyRepo
abstract class BaseEntityRepo<T> {
  final Box<T> _box;

  BaseEntityRepo({required Box<T> box}) : _box = box;

  // Save entity to the database
  void save(T entity) {
    _box.put(entity);
  }

  // Get all entities
  List<T> getAll() {
    final query = _box.query().build();
    final allEntities = query.find();
    query.close();
    return allEntities;
  }

  // Get entity by ID
  T? getById(int id) {
    return _box.get(id);
  }

  // Delete entity
  void delete(int id) {
    _box.remove(id);
  }

  // Delete all entities
  void deleteAll() {
    _box.removeAll();
  }
}
