import 'package:sqflite/sqlite_api.dart';
import 'package:wazeloquent/src/enums/operator.dart';
import 'package:wazeloquent/src/models/model.dart';
import 'package:wazeloquent/src/support/generator.dart';

abstract class RelationshipModel extends Model with Generator {
  String? query;
  String? pivotTable;
  String? finalForeignKey;
  String? finalParentKey;

  @override
  resetAll() {
    pivotTable = null;
    finalForeignKey = null;
    finalParentKey = null;
    query = null;
    super.resetAll();
  }

  @override
  List<String> get columns => eloquent.columns;

  @override
  String get getPrimaryColumn => eloquent.getPrimaryColumn;

  @override
  String get tableName => eloquent.tableName;

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
    if (query == null) {
      throw Exception('cannot query without relationship');
    }
    String q = 'SELECT table1.* from ' + query!;
    try {
      Database _db = await eloquent.getDatabase;
      resetAll();
      return await _db.rawQuery(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }

  /// Get the rows.
  /// ```
  /// var userEloquent = UserEloquent();
  /// userEloquent.get();
  /// ```
  @override
  Future<List<Map<String, Object?>>?> get() async {
    if (query == null) {
      throw Exception('cannot query without relationship');
    }
    String? selectedColumns = getSelectedColumns(table: 'table1');
    String q = 'SELECT ${selectedColumns ?? 'table1.*'} from ' + query!;
    try {
      q = generateQuery(q, table: 'table1');
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
  Future<int> create(Map<String, Object?> values) async {
    if (values.isEmpty) {
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
    if (!values.keys.contains(finalForeignKey)) {
      values[finalForeignKey!] = primaryValue;
    }
    resetAll();
    return await db.insert(table, values);
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
    if (values.isEmpty) {
      throw Exception('Empty values');
    }
    if (query == null) {
      super.update(values);
    }
    String table = query!.split(' ')[0];
    String q = 'SELECT table1.id FROM ' + query!;
    try {
      resetDistinct();
      resetGroupBy();
      resetSelectedColunns();
      resetSort();
      String selectedQuery = generateQuery(q);
      q = 'UPDATE $table ';
      for (var val in values.entries) {
        if (columns.contains(val.key)) {
          q += ' SET ${val.key} = "${val.value}"';
          if (val.key != values.keys.last) {
            q += ',';
          }
        }
      }
      q = q + ' WHERE id IN ($selectedQuery)';
      final db = await eloquent.getDatabase;
      resetAll();
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
    if (query == null) {
      return super.delete();
    }
    String q = 'SELECT table1.id FROM ' + query!;
    try {
      resetSelectedColunns();
      resetDistinct();
      resetOrderBy();
      resetGroupBy();
      resetLimit();
      resetLimit();
      resetOffset();
      q = generateQuery(q);
      String table = query!.split(' ')[0];
      q = 'DELETE from $table WHERE id IN ($q)';
      resetAll();

      Database _db = await eloquent.getDatabase;
      return await _db.rawDelete(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
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
    if (query == null) {
      throw Exception('cannot query without relationship');
    }
    String _key = '%$keyword%';
    String? selectedColumns = getSelectedColumns(table: 'table1');
    String table = query!.split(' ')[0];
    String q =
        'SELECT ${selectedColumns ?? 'table1.*'} from ' + query! + ' AND ';
    try {
      List<String>? _usedColumns;
      var _wheres = getWhereColumns();
      if (_wheres.isNotEmpty) {
        _usedColumns = _wheres.map((e) => e.columnName).toList();
      }
      if (searchableColumns != null && searchableColumns.isNotEmpty) {
        for (var column in searchableColumns) {
          where(column, _key, operator: Operator.like, conjuncation: 'or');
        }
      } else {
        for (var column in await eloquent.getColumnNames(table: table)) {
          if (_usedColumns != null && _usedColumns.contains(column)) {
            continue;
          }
          where(column, _key, operator: Operator.like, conjuncation: 'or');
        }
      }
      q = generateQuery(q, table: 'table1');
      Database _db = await eloquent.getDatabase;
      resetAll();
      return await _db.rawQuery(q);
    } catch (e) {
      throw Exception('Generated query: "$q" \n' + e.toString());
    }
  }
}
