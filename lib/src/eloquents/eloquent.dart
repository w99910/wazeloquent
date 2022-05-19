import 'package:wazeloquent/src/enums/operator.dart';
import 'package:wazeloquent/src/support/generator.dart';
import 'package:wazeloquent/wazeloquent.dart';

abstract class Eloquent with Generator {
  Future<Database> get getDatabase async => DB.instance.getDB();

  Future<List<String>> getColumnNames(String table) async {
    Database _db = await getDatabase;
    var data = await _db.rawQuery("PRAGMA table_info(" + table + ")", null);
    return data.map((e) => e['name'].toString()).toList();
  }

  Future<List<Map<String, dynamic>>> getForeignKeys(String table) async {
    Database _db = await getDatabase;
    var data =
        await _db.rawQuery("PRAGMA foreign_key_list(" + table + ")", null);
    List<Map<String, dynamic>> results = [];
    if (data.isNotEmpty) {
      for (var row in data) {
        Map<String, dynamic> result = {};
        result['id'] = row[0];
        result['seq'] = row[1];
        result['table'] = row[2];
        result['from'] = row[3];
        result['to'] = row[4];
        result['onUpdate'] = row[5];
        result['onDelete'] = row[6];
        result['match'] = row[7];
        results.add(result);
      }
    }
    return results;
  }

  /// Return all rows from table.
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// //similar to userEloquent.get() but no matter what options you specify, they will be ignored and all rows will be returned.
  /// userEloquent.all();
  ///
  /// //orderBy, limit will be ignored
  /// userEloquent.orderBy('name').limit(1).all();
  /// ```
  @override
  Future<List<Map<String, Object?>>> all() async {
    String query = 'SELECT';
    try {
      Database _db = await getDatabase;
      resetAll();
      query += generateQuery('*');

      return await _db.rawQuery(query);
    } catch (e) {
      throw Exception('Generated query: "$query" \n' + e.toString());
    }
  }

  /// Final execution of query is performed by issuing this method.
  /// ```
  /// var userEloquent = UserEloquent();
  /// userEloquent.get();
  /// ```
  @override
  Future<List<Map<String, Object?>>?> get() async {
    String q = 'Select';
    try {
      q += generateQuery(getSelectedColumns() ?? '*');

      resetAll();

      Database _db = await getDatabase;
      return await _db.rawQuery(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }

  /// Find row by primary key.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // get user where primary key (id) is 1.
  /// userEloquent.find(1);
  /// ```
  Future<Map<String, Object?>?> find(primaryKeyValue) async {
    Database _db = await getDatabase;
    var results = await _db.query(
      tableName,
      columns: columns,
      where: getPrimaryColumn + ' = ?',
      whereArgs: [primaryKeyValue],
    );
    resetAll();
    if (results.isNotEmpty) {
      return results[0];
    }
    return null;
  }

  /// Search rows.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // get rows where any column has word 'j'.
  /// userEloquent.search('j');
  ///
  /// // get rows where country has 'UK' and any other rows has 'j'.
  /// userEloquent.where('country','UK').search('j');
  ///
  /// //specify searchable columns
  /// userEloquent.search('j',searchableColumns:['name']);
  /// ```
  @override
  Future<List<Map<String, Object?>>> search(String keyword,
      {List<String>? searchableColumns}) async {
    String _key = '%$keyword%';
    String q = 'Select';
    try {
      List<String>? _usedColumns;
      var _wheres = getWhereColumns();
      if (_wheres.isNotEmpty) {
        _usedColumns = _wheres.map((e) => e.columnName).toList();
        _wheres = [];
      }
      if (searchableColumns != null && searchableColumns.isNotEmpty) {
        for (var column in searchableColumns) {
          where(column, _key, operator: Operator.like, conjuncation: 'or');
        }
      } else {
        for (var column in columns) {
          if (_usedColumns != null && _usedColumns.contains(column)) {
            continue;
          }
          where(column, _key, operator: Operator.like, conjuncation: 'or');
        }
      }
      q += generateQuery(getSelectedColumns() ?? '*');
      resetAll();
      Database _db = await getDatabase;
      return await _db.rawQuery(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }

  /// Create a new row.
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// userEloquent.create({'name':'John','password':'pass'});
  ///
  /// ```
  @override
  Future<int> create({required Map<String, Object?> values}) async {
    resetAll();
    final db = await getDatabase;
    return await db.insert(tableName, values);
  }

  Future<List<Map<String, Object?>>> _where(Map<String, Object?> object) async {
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

  /// Create a new row only if the value is not existed.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  // create user which name is john and password is pass only if name 'john' is not existed.
  /// userEloquent.createIfNotExists(check:{'name':'john'},create:{'password':'pass'});
  ///
  /// ```
  Future<int?> createIfNotExists(
      {required Map<String, Object?> check,
      required Map<String, Object?> create}) async {
    final db = await getDatabase;
    List result = await _where(check);
    if (result.isNotEmpty) {
      return null;
    }
    create.addAll(check);
    resetAll();
    return await db.insert(tableName, create);
  }

  /// Update data if exists and if not, create new row.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // if row where name is john exists, update 'password' column. If not, create row where name is john and password is 'pass'.
  /// userEloquent.updateOrCreate(check:{'name':'john'},inserts:{'password':'pass'});
  ///```
  Future<int> updateOrCreate(
      {required Map<String, Object?> check,
      required Map<String, Object?> inserts}) async {
    final db = await getDatabase;
    List checkResult = await _where(check);
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
    resetAll();
    return await db.insert(tableName, {...check, ...inserts});
  }

  /// Update rows and return number of changes.

  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // update name of all rows to 'john'.
  /// userEloquent.update({'name':'john'});
  ///
  /// // update name of rows where id = 1 to 1.
  /// userEloquent.where('id',1).update({'name':'john'});
  ///
  /// ```
  @override
  Future<int> update(Map<String, Object?> values) async {
    String q = 'Update $tableName';
    try {
      for (var val in values.entries) {
        if (columns.contains(val.key)) {
          q += ' SET ${val.key} = "${val.value}"';
          if (val.key != values.keys.last) {
            q += ',';
          }
        }
      }

      resetDistinct();
      resetGroupBy();
      resetSelectedColunns();
      resetSort();
      q = generateQuery(q);
      resetAll();
      final db = await getDatabase;
      return await db.rawUpdate(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }

  ///   Delete rows from table and return number of changes.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // delete all rows from users
  /// userEloquent.delete();
  ///
  /// // delete rows where name has 'j' from users
  /// userEloquent.where('name','%j%',operator:Operator.like).delete();
  ///
  /// ```
  @override
  Future<int> delete() async {
    String query = 'Delete';
    try {
      resetSelectedColunns();
      resetDistinct();
      resetOrderBy();
      resetGroupBy();
      resetLimit();
      resetLimit();
      resetOffset();
      query += generateQuery('');

      resetAll();

      Database _db = await getDatabase;
      return await _db.rawDelete(query);
    } catch (e) {
      throw Exception('Generated query: "$query" \n' + e.toString());
    }
  }

  ///  Delete a row by primary key.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // delete row where primary key is 1
  /// userEloquent.deleteBy(1);
  /// ```
  Future<int> deleteBy(value) async {
    Database _db = await getDatabase;
    return await _db.delete(
      tableName,
      where: getPrimaryColumn + ' = ?',
      whereArgs: [value],
    );
  }
}
