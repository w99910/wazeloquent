import 'package:wazeloquent/wazeloquent.dart';

mixin OneToMany on Model {
  Future<Map<String, Object?>?> belongsTo(String table,
      {String? foreignKey, String? parentKey}) async {
    String? q;
    try {
      Database _db = await eloquent.getDatabase;
      String? _foreignKey;
      String? _parentKey;
      String childTable = eloquent.tableName;
      if (foreignKey == null) {
        List<String> columNames = await eloquent.getColumnNames(childTable);
        List possibleColumnNames = columNames
            .where((element) =>
                element.contains(table.substring(0, childTable.length - 2)))
            .toList();
        if (possibleColumnNames.isEmpty) {
          throw Exception(
              'foreignKey not found. Please specify custom foreignKey arg');
        }
        _foreignKey = possibleColumnNames.first;
      } else {
        _foreignKey = foreignKey;
      }

      if (!_foreignKey!.contains('_')) {
        throw Exception('Foreign Key should have underscore e.g. car_id');
      }

      if (parentKey == null) {
        String parentColumn = _foreignKey.split('_')[1];
        List<String> columNames = await eloquent.getColumnNames(table);
        if (!columNames.contains(parentColumn)) {
          throw Exception('parent key not found in parent table');
        }
        _parentKey = parentColumn;
      } else {
        _parentKey = parentKey;
      }

      q = 'Select parent.* from $table parent, $childTable child WHERE child.$_foreignKey = parent.$_parentKey AND child.${eloquent.getPrimaryColumn} = "$primaryValue"';

      var results = await _db.rawQuery(q);
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      throw Exception(e.toString() + '\n $q');
    }
  }

  Future<List<Map<String, Object?>>> hasMany(String table,
      {String? foreignKey, String? parentKey}) async {
    String? q;
    try {
      Database _db = await eloquent.getDatabase;
      String? _foreignKey;
      String? _parentKey;
      String childTableName = table;
      String parentTableName = eloquent.tableName;
      if (foreignKey == null) {
        List<String> columNames = await eloquent.getColumnNames(childTableName);
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
      q = 'Select child.* from $childTableName child, $parentTableName parent WHERE child.$_foreignKey = parent.$_parentKey AND parent.${eloquent.getPrimaryColumn} = "$primaryValue"';

      var results = await _db.rawQuery(q);
      return results;
    } catch (e) {
      throw Exception(e.toString() + '\n $q');
    }
  }
}
