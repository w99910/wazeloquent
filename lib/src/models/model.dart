import 'package:wazeloquent/wazeloquent.dart';

abstract class Model {
  Eloquent get eloquent;

  String get primaryValue;

  Map<String, Object?> get toJson;

  /// Create record in related table if not exists depending on primary value
  /// Otherwise update the values.
  Future<int> save() async {
    return await eloquent
        .where(eloquent.getPrimaryColumn, primaryValue)
        .updateOrCreate(
            check: {eloquent.getPrimaryColumn: primaryValue}, inserts: toJson);
  }

  Future<int> update(Map<String, Object?> values) {
    return eloquent
        .where(eloquent.getPrimaryColumn, primaryValue)
        .update(values);
  }

  Future<int> delete() async {
    return await eloquent.deleteBy(primaryValue);
  }
}
