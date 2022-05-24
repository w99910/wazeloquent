import 'package:wazeloquent/src/models/relationship_model.dart';

mixin OneToMany on RelationshipModel {
  /// If `foreignKey` is not specified, `foreignKey` will be issumed as the first column which contains `parent` table name the in the child table.
  /// e.g for a car belonging to a user, foreignKey will be assumed as `user_id` which includes the name of parentTable.
  ///
  /// If `parentKey` is not specified, `parentKey` will be assumed as the word which is after `_`(underscore) of `foreginKey`. For example, in the case of foreign key `user_id`, `id` will be `parentKey`.
  ///
  /// ```dart
  /// class Car extends Model with OneToOne{
  ///  Future<Car?> getUser() async {
  ///     var user = await belongsTo('users');
  ///   }
  /// }
  /// ```
  Future<OneToMany> belongsTo(String parentTable,
      {String? foreignKey, String? parentKey}) async {
    String? _foreignKey;
    String? _parentKey;
    String childTable = eloquent.tableName;
    List<Map<String, dynamic>> foreignKeys =
        (await eloquent.getForeignKeys(table: childTable))
            .where((element) => element['table'] == parentTable)
            .toList();
    if (foreignKeys.isEmpty) {
      throw Exception(
          'There is no foreign key related to $parentTable in $tableName');
    }

    Map<String, dynamic>? foreignInfo;
    if (foreignKeys.length > 1 && foreignKey == null) {
      throw Exception(
          'Please specify foreign key since there are more than one foreign keys in $tableName');
    }

    if (foreignKey == null) {
      foreignInfo = foreignKeys.first;
      _foreignKey = foreignInfo['from'];
    } else {
      if (foreignKeys
          .where((element) => element['from'] == foreignKey)
          .isEmpty) {
        throw Exception('foreign Key not found');
      }
      foreignInfo = foreignKeys.firstWhere(
          (element) => element['from'] == foreignKey,
          orElse: () => {});
      _foreignKey = foreignKey;
    }

    if (parentKey == null) {
      _parentKey = foreignInfo['to'];
    } else {
      List<String> columNames =
          await eloquent.getColumnNames(table: parentTable);
      if (!columNames.contains(parentKey)) {
        throw Exception('parent key not found in parent table');
      }
      _parentKey = parentKey;
    }

    query =
        '$parentTable table1, $childTable table2 WHERE table2.$_foreignKey = table1.$_parentKey AND table2.${eloquent.getPrimaryColumn} = "$primaryValue"';
    return this;
  }

  /// If `foreignKey` is not specified, `foreignKey` will be issumed as the first column which contains `parent` table name the in the child table.
  /// e.g for a user having **a car or many cars**, foreignKey will be assumed as `user_id` which includes the name of parentTable in child table.
  ///
  /// If `parentKey` is not specified, `parentKey` will be assumed as the word which is after `_`(underscore) of `foreginKey`. For example, in the case of foreign key `user_id`, `id` will be `parentKey`.
  ///
  /// ```dart
  /// class User extends Model with OneToOne{
  ///  Future<Car?> getCar() async {
  ///     var car = await hasMany('cars');
  ///   }
  /// }
  /// ```
  Future<OneToMany> hasMany(String childTable,
      {String? foreignKey, String? parentKey}) async {
    String? _foreignKey;
    String? _parentKey;
    String parentTable = eloquent.tableName;
    List<Map<String, dynamic>> foreignKeys =
        (await eloquent.getForeignKeys(table: childTable))
            .where((element) => element['table'] == parentTable)
            .toList();
    if (foreignKeys.isEmpty) {
      throw Exception(
          'There is no foreign key related to $parentTable in $tableName');
    }

    Map<String, dynamic>? foreignInfo;
    if (foreignKeys.length > 1 && foreignKey == null) {
      throw Exception(
          'Please specify foreign key since there are more than one foreign keys in $tableName');
    }
    if (foreignKey == null) {
      foreignInfo = foreignKeys.first;
      _foreignKey = foreignInfo['from'];
    } else {
      if (foreignKeys
          .where((element) => element['from'] == foreignKey)
          .isEmpty) {
        throw Exception('foreign Key not found');
      }
      foreignInfo = foreignKeys.firstWhere(
          (element) => element['from'] == foreignKey,
          orElse: () => {});
      _foreignKey = foreignKey;
    }
    if (parentKey == null) {
      _parentKey = foreignInfo['to'];
    } else {
      List<String> columNames =
          await eloquent.getColumnNames(table: parentTable);
      if (!columNames.contains(parentKey)) {
        throw Exception('parent key not found in parent table');
      }
      _parentKey = parentKey;
    }
    query =
        '$childTable table1, $parentTable table2 WHERE table1.$_foreignKey = table2.$_parentKey AND table2.${eloquent.getPrimaryColumn} = "$primaryValue"';
    return this;
  }

  Future<List<int>> createMany(List<Map<String, Object?>> items) async {
    if (items.isEmpty) {
      throw Exception('Empty values');
    }
    if (query == null) {
      throw Exception('cannot query without relationship');
    }
    String table = query!.split(' ')[0];
    if (!(await eloquent.getColumnNames(table: table))
        .contains(finalForeignKey)) {
      throw Exception('cannot create parent data from child.');
    }
    final db = await eloquent.getDatabase;
    List<int> ids = [];
    for (var item in items) {
      if (!item.keys.contains(finalForeignKey)) {
        item[finalForeignKey!] = primaryValue;
      }
      ids.add(await db.insert(table, item));
    }

    resetAll();
    return ids;
  }
}
