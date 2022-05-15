import 'package:wazeloquent/wazeloquent.dart';

abstract class Model {
  Eloquent get eloquent;

  String get primaryValue;

  Map<String, Object?> get toJson;

  Future<int> save() async {
    return await eloquent
        .where(eloquent.getPrimaryColumn, primaryValue)
        .update(toJson);
  }

  Future<int> delete() async {
    return await eloquent.deleteBy(primaryValue);
  }
}
