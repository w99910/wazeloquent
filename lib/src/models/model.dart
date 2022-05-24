import 'package:wazeloquent/wazeloquent.dart';

abstract class Model {
  Eloquent get eloquent;

  dynamic get primaryValue;

  Map<String, Object?> get toJson;

  setPrimaryValue(value);

  /// Create record in related table if not exists depending on primary value
  /// Otherwise update the values.
  Future<int> save() async {
    var status = await eloquent
        .where(eloquent.getPrimaryColumn, primaryValue)
        .updateOrCreate(
            check: {eloquent.getPrimaryColumn: primaryValue}, inserts: toJson);
    if (status != 0) {
      setPrimaryValue(status);
    }
    return status;
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
