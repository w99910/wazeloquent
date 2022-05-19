import 'package:sqflite/sqlite_api.dart';
import 'package:wazeloquent/src/enums/operator.dart';
import 'package:wazeloquent/src/models/model.dart';
import 'package:wazeloquent/src/support/generator.dart';

abstract class RelationshipModel extends Model with Generator {
  bool isRelationship = false;

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
      Database _db = await eloquent.getDatabase;
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

      Database _db = await eloquent.getDatabase;
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
    final db = await eloquent.getDatabase;
    return await db.insert(tableName, values);
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
    if (!isRelationship) {
      super.update(values);
    }
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
      final db = await eloquent.getDatabase;
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

      Database _db = await eloquent.getDatabase;
      return await _db.rawDelete(query);
    } catch (e) {
      throw Exception('Generated query: "$query" \n' + e.toString());
    }
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
      Database _db = await eloquent.getDatabase;
      return await _db.rawQuery(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }
}
