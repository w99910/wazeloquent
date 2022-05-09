import 'dart:developer';

import 'package:sqflite/sqflite.dart';
import 'package:wazeloquent/src/support/database.dart';

abstract class BaseEloquent {
  List<String> get columns;

  Map<String, dynamic> from(Map<String, dynamic> entry);

  String get tableName;

  static Future<Database> get getDatabase async => DB.instance.getDB();

  String getPrimaryColumn();

  Future<List<Map<String, Object?>>> all(
      {int? limit,
      String? orderBy,
      String? groupBy,
      bool? distinct,
      bool descending = false,
      int? offset}) async {
    Database _db = await getDatabase;
    String query = 'SELECT';
    if (distinct != null && distinct) {
      query += ' Distinct ';
      for (var column in columns.asMap().entries) {
        query += column.value;
        if (column.key != columns.length - 1) {
          query += ', ';
        }
      }
    } else {
      query += ' *';
    }
    query += ' FROM $tableName';
    if (orderBy != null) {
      query += ' ORDER BY $orderBy ${descending ? 'DESC' : 'ASC'}';
    }

    if (groupBy != null) {
      query += ' GROUP BY $groupBy';
    }

    if (limit != null) {
      query += ' LIMIT ';
      query += offset != null ? '$offset, $limit' : '$limit';
    }

    return await _db.rawQuery(query);
  }

  Map<String, Map<String, String>> _manyToMany = {};

  void hasMany(
      {required String foreignKey,
      required String pivotTable,
      required String parentKey,
      required String parentTable}) {
    _manyToMany[pivotTable] = {
      'foreignKey': foreignKey,
      'parentKey': parentKey,
      'parentTable': parentTable,
    };
  }

  Future<List<Map<String, Object?>>?> many(
      {required value, required String pivotTable}) async {
    if (!_manyToMany.containsKey(pivotTable)) {
      return null;
    }
    String foreignKey = _manyToMany[pivotTable]!['foreignKey']!;
    String parentKey = _manyToMany[pivotTable]!['parentKey']!;
    String parentTable = _manyToMany[pivotTable]!['parentTable']!;
    var query = 'SELECT * FROM $tableName a LEFT JOIN $pivotTable pt ON pt.';
    return [{}];
  }

  Future<List<Map<String, Object?>>> raw(String query) async {
    Database _db = await getDatabase;
    return await _db.rawQuery(query);
  }

  Future<List<Map<String, Object?>>> select(
      {required List<String> columns}) async {
    Database _db = await getDatabase;
    String select = '';
    for (var column in columns.asMap().entries) {
      select += column.value;
      if (column.key != columns.length - 1) {
        select += ',';
      }
    }
    inspect(select);
    return await _db.rawQuery('SELECT $select FROM $tableName');
  }

  Future<List<Map<String, Object?>>> where(Map<String, Object?> object) async {
    Database _db = await getDatabase;
    var where = '';
    var whereArgs = [];
    object.forEach((key, value) {
      where = where == '' ? key + ' = ?' : where + ' and ' + key + ' = ?';
      whereArgs.add(value);
    });
    return await _db.query(tableName,
        columns: columns, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> greaterThanAndWhere(
      String greaterThanColumn, dynamic greaterThanValue,
      {Map<String, Object?>? options}) async {
    Database _db = await getDatabase;
    var where = '';
    var whereArgs = [];
    if (options != null) {
      options.forEach((key, value) {
        where = where == '' ? key + ' = ?' : where + ' and ' + key + ' = ?';
        whereArgs.add(value);
      });
    }
    where = where == ''
        ? '$greaterThanColumn > ?'
        : where + ' and ' + greaterThanColumn + ' > ?';
    whereArgs.add(greaterThanValue);
    return await _db.query(tableName,
        columns: columns, where: where, whereArgs: whereArgs);
  }

  Future lessThanAndWhere(String lessThanColumn, dynamic lessThanValue,
      {Map<String, Object?>? options}) async {
    Database _db = await getDatabase;
    var where = '';
    var whereArgs = [];
    if (options != null) {
      options.forEach((key, value) {
        where = where == '' ? key + ' = ?' : where + ' and ' + key + ' = ?';
        whereArgs.add(value);
      });
    }
    where = where == ''
        ? '$lessThanColumn < ?'
        : where + ' and ' + lessThanColumn + ' < ?';
    whereArgs.add(lessThanValue);
    return await _db.query(tableName,
        columns: columns, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, Object?>>> distinct(String column,
      {Map<String, Object?>? options, String? orderBy}) async {
    Database _db = await getDatabase;
    var query = 'SELECT DISTINCT $column FROM $tableName';
    if (options != null) {
      var where = '';
      options.forEach((key, value) {
        where = where == ''
            ? key + ' = $value'
            : where + ' and ' + key + ' = $value';
      });
      query += ' WHERE $where';
    }
    if (orderBy != null) {
      query += 'ORDER BY $orderBy';
    }
    return await _db.rawQuery(query);
  }

  Future<Map<String, Object?>?> latest({String? sortBy}) async {
    sortBy ??= getPrimaryColumn();
    Database _db = await getDatabase;
    var result = await _db
        .rawQuery('SELECT * FROM $tableName ORDER BY $sortBy DESC LIMIT 1;');
    if (result.isNotEmpty) return result[0];
    return null;
  }

  Future<List<Map<String, Object?>>> searchByKeyWord(String keyword,
      {Map<String, dynamic>? options, List<String>? searchableColumns}) async {
    String _key = '%$keyword%';
    String whereOr = '';
    List<String> whereArgs = [];
    List<String> optionKeys = [];
    if (options != null && options.isNotEmpty) {
      optionKeys = options.keys.toList();
    }
    String whereAnd = '';
    for (var col in columns) {
      if (optionKeys.contains(col)) {
        whereAnd =
            whereAnd == '' ? col + ' = ? and ' : col + ' = ? and ' + whereAnd;
        whereArgs.insert(0, options![col]!.toString());
      } else {
        if (searchableColumns != null && searchableColumns.isNotEmpty) {
          if (searchableColumns.contains(col)) {
            whereOr = whereOr == ''
                ? '( ' + col + ' LIKE ?'
                : whereOr + ' or ' + col + ' LIKE ?';
            whereArgs.add(_key);
          }
        } else {
          whereOr = whereOr == ''
              ? '( ' + col + ' LIKE ?'
              : whereOr + ' or ' + col + ' LIKE ?';
          whereArgs.add(_key);
        }
      }
    }
    String where = whereAnd + whereOr + ')';
    Database _db = await getDatabase;
    return await _db.query(
      tableName,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<Map<String, Object?>?> find(primaryKeyValue) async {
    Database _db = await getDatabase;
    var results = await _db.query(
      tableName,
      columns: columns,
      where: getPrimaryColumn() + ' = ?',
      whereArgs: [primaryKeyValue],
    );
    if (results.isNotEmpty) {
      return results[0];
    }
    return null;
  }

  Future<int> deleteBy(primaryKeyValue, {String? column}) async {
    Database _db = await getDatabase;
    return await _db.delete(
      tableName,
      where: (column ?? getPrimaryColumn()) + ' = ?',
      whereArgs: [primaryKeyValue],
    );
  }

  Future<List<Map<String, Object?>>?> deleteWhereIn(List values,
      {String? checkColumn}) async {
    checkColumn ??= getPrimaryColumn();
    Database _db = await getDatabase;
    if (values.isEmpty) {
      return null;
    }
    String deleteValues = '(';
    values.asMap().entries.forEach((element) {
      deleteValues += '"${element.value}"';
      if (element.key == values.length - 1) {
        deleteValues += ')';
      } else {
        deleteValues += ',';
      }
    });
    return await _db.rawQuery('DELETE FROM ' +
        tableName +
        ' WHERE ' +
        checkColumn +
        ' IN' +
        deleteValues);
  }

  Future<List<Map<String, Object?>>?> deleteWhereNotIn(List values,
      {String? checkColumn}) async {
    checkColumn ??= getPrimaryColumn();
    Database _db = await getDatabase;
    if (values.isEmpty) {
      return null;
    }
    String deleteValues = '(';
    values.asMap().entries.forEach((element) {
      deleteValues += '"${element.value}"';
      if (element.key == values.length - 1) {
        deleteValues += ')';
      } else {
        deleteValues += ',';
      }
    });
    return await _db.rawQuery('DELETE FROM ' +
        tableName +
        ' WHERE ' +
        checkColumn +
        ' NOT IN ' +
        deleteValues);
  }

  Future<int> create({required Map<String, Object?> values}) async {
    final db = await getDatabase;
    return await db.insert(tableName, values);
  }

  Future<int> createIfNotExists(
      {required Map<String, Object?> check,
      required Map<String, Object?> create}) async {
    final db = await getDatabase;
    List result = await where(check);
    if (result.isNotEmpty) {
      return result.first;
    }
    return await db.insert(tableName, create);
  }

  Future<int> updateOrCreate(
      {required Map<String, Object?> check,
      required Map<String, Object?> inserts}) async {
    final db = await getDatabase;
    List checkResult = await where(check);
    if (checkResult.isNotEmpty) {
      var where = '';
      var whereArgs = [];
      check.forEach((key, value) {
        where = where == '' ? key + ' = ?' : where + ' and ' + key + ' = ?';
        whereArgs.add(value);
      });
      return await db.update(
          tableName,
          Map.fromEntries(
              inserts.entries.where((element) => element.key != 'isFavourite')),
          where: where,
          whereArgs: whereArgs);
    }
    return await db.insert(tableName, {...check, ...inserts});
  }

  Future<int> createFromJson(Map<String, dynamic> json) async {
    final db = await getDatabase;
    return await db.insert(tableName, from(json));
  }

  Future<int> update(primaryKey, Map<String, Object?> object) async {
    final db = await getDatabase;
    return await db.update(tableName, object,
        where: getPrimaryColumn() + ' = ?', whereArgs: [primaryKey]);
  }

  Future<int> updateAll(Map<String, Object?> object) async {
    final db = await getDatabase;
    return await db.update(tableName, object);
  }

  Future<void> close() async {
    final db = await getDatabase;
    await db.close();
  }

  Future<int> deleteDB() async {
    final db = await getDatabase;
    return await db.delete(tableName);
  }
}
