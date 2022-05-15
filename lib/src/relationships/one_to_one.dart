import 'package:wazeloquent/wazeloquent.dart';

mixin OneToOne on Model {
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
  Future<Map<String, Object?>?> belongsTo(String parentTable,
      {String? foreignKey, String? parentKey}) async {
    String? q;
    try {
      Database _db = await eloquent.getDatabase;
      String? _foreignKey;
      String? _parentKey;
      String childTable = eloquent.tableName;
      List<String> columNames = await eloquent.getColumnNames(childTable);
      if (foreignKey == null) {
        List possibleColumnNames = columNames
            .where((element) => element
                .contains(parentTable.substring(0, parentTable.length - 2)))
            .toList();
        if (possibleColumnNames.isEmpty) {
          throw Exception(
              'foreignKey not found. Please specify custom foreignKey arg');
        }
        _foreignKey = possibleColumnNames.first;
      } else {
        if (!columNames.contains(foreignKey)) {
          throw Exception('foreign Key not found');
        }
        _foreignKey = foreignKey;
      }

      if (!_foreignKey!.contains('_')) {
        throw Exception('Foreign Key should have underscore e.g. car_id');
      }

      if (parentKey == null) {
        String parentColumn = _foreignKey.split('_')[1];
        List<String> columNames = await eloquent.getColumnNames(parentTable);
        if (!columNames.contains(parentColumn)) {
          throw Exception('parent key not found in parent table');
        }
        _parentKey = parentColumn;
      } else {
        _parentKey = parentKey;
      }

      q = 'Select parent.* from $parentTable parent, $childTable child WHERE child.$_foreignKey = parent.$_parentKey AND child.${eloquent.getPrimaryColumn} = "$primaryValue"';

      var results = await _db.rawQuery(q);
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }

  /// If `foreignKey` is not specified, `foreignKey` will be issumed as the first column which contains `parent` table name the in the child table.
  /// e.g for a user having a car, foreignKey will be assumed as `user_id` which includes the name of parentTable in child table.
  ///
  /// If `parentKey` is not specified, `parentKey` will be assumed as the word which is after `_`(underscore) of `foreginKey`. For example, in the case of foreign key `user_id`, `id` will be `parentKey`.
  ///
  /// ```dart
  /// class User extends Model with OneToOne{
  ///  Future<Car?> getCar() async {
  ///     var car = await hasOne('cars');
  ///   }
  /// }
  /// ```
  Future<Map<String, Object?>?> hasOne(String childTable,
      {String? foreignKey, String? parentKey}) async {
    String? q;
    try {
      Database _db = await eloquent.getDatabase;
      String? _foreignKey;
      String? _parentKey;
      String parentTableName = eloquent.tableName;
      List<String> columNames = await eloquent.getColumnNames(childTable);
      if (foreignKey == null) {
        List possibleColumnNames = columNames
            .where((element) => element.contains(
                parentTableName.substring(0, parentTableName.length - 2)))
            .toList();
        if (possibleColumnNames.isEmpty) {
          throw Exception(
              'foreignKey not found. Please specify custom foreignKey arg');
        }
        _foreignKey = possibleColumnNames.first;
      } else {
        if (!columNames.contains(foreignKey)) {
          throw Exception('foreign Key not found');
        }
        _foreignKey = foreignKey;
      }

      if (!_foreignKey!.contains('_')) {
        throw Exception('Foreign Key must have underscore e.g. car_id');
      }

      if (parentKey == null) {
        String parentColumn = _foreignKey.split('_')[1];
        List<String> columNames =
            await eloquent.getColumnNames(parentTableName);
        if (!columNames.contains(parentColumn)) {
          throw Exception('parent key not found in parent table');
        }
        _parentKey = parentColumn;
      } else {
        _parentKey = parentKey;
      }
      q = 'Select child.* from $childTable child, $parentTableName parent WHERE child.$_foreignKey = parent.$_parentKey AND parent.${eloquent.getPrimaryColumn} = "$primaryValue"';
      q += ' LIMIT 1';

      var results = await _db.rawQuery(q);
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }
}
