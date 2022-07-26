import 'package:wazeloquent/wazeloquent.dart';

abstract class Model {
  Eloquent get eloquent;

  dynamic get primaryValue;

  /// Structure the object to be inserted when executing `save` method.
  ///
  /// For more information, see `save` method.
  Map<String, Object?> get toJson;

  /// Update the primary value automatically when `save` method is executed.
  ///
  /// For example,
  /// ```dart
  /// // user.dart
  /// setPrimaryValue(value){
  ///   id = value;
  /// }
  ///
  /// var user = User(name:'John');
  /// // The above record does not exist in table. So let's create record using save() method
  /// user.save();
  ///
  /// // So user.id will be the primary value of inserted record in table.
  ///
  /// ```
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
