import 'package:wazeloquent/wazeloquent.dart';

abstract class Eloquent {
  List<String> get columns;

  String get tableName;

  static Future<Database> get getDatabase async => DB.instance.getDB();

  String get getPrimaryColumn;

  String? _orderBy;

  String? _groupBy;

  bool _distinct = false;

  Sort? _sort;

  int? _offset;

  int? _limit;

  List<String>? _selectedColumns;

  List<_Where> _wheres = [];

  _reset() {
    _orderBy = null;
    _groupBy = null;
    _distinct = false;
    _sort = null;
    _offset = null;
    _limit = null;
    _selectedColumns = null;
    _wheres = [];
  }

  String? _getSelectedColumns() {
    return _toString(_selectedColumns);
  }

  String? _toString(List<String>? values) {
    String? val;
    if (values != null && values.isNotEmpty) {
      val = '';
      for (var col in _selectedColumns!.asMap().entries) {
        val = val! + col.value;
        if (col.key != _selectedColumns!.length - 1) {
          val = val + ',';
        }
      }
    }
    return val;
  }

  String _getWhereQuery(String q) {
    if (_wheres.isNotEmpty) {
      q += ' WHERE';
      var _queryableWheres =
          _wheres.where((element) => columns.contains(element.columnName));
      var whereAnd = _queryableWheres
          .where((element) => element.conjunction == 'and')
          .toList();
      var whereOr = _queryableWheres
          .where((element) => element.conjunction == 'or')
          .toList();
      for (var where in whereAnd.asMap().entries) {
        q +=
            ' ${where.value.columnName} ${where.value.operator} "${where.value.value}"';
        if (where.key != _wheres.length - 1) {
          q += ' ${where.value.conjunction}';
        }
      }
      for (var where in whereOr.asMap().entries) {
        if (where.key == 0) {
          q += ' (';
        }
        q +=
            ' ${where.value.columnName} ${where.value.operator} "${where.value.value}"';
        if (where.key != _wheres.length - 1) {
          q += ' ${where.value.conjunction}';
        } else {
          q += ' )';
        }
      }
    }
    return q;
  }

  String _getOrderBy(String q) {
    if (_orderBy != null) {
      q += ' ORDER BY `$_orderBy`';
      if (_sort != null) {
        switch (_sort!) {
          case Sort.ascending:
            q += ' ASC';
            break;
          case Sort.descending:
            q += ' DESC';
            break;
        }
      }
    }
    return q;
  }

  String _getGroupBy(String q) {
    if (_groupBy != null) {
      q += ' GROUP BY `$_groupBy`';
      if (_sort != null) {
        switch (_sort!) {
          case Sort.ascending:
            q += ' ASC';
            break;
          case Sort.descending:
            q += ' DESC';
            break;
        }
      }
    }
    return q;
  }

  String _getLimitOffset(String q) {
    q += ' LIMIT ${_limit ?? '-1'}';
    if (_offset != null) {
      q += ' OFFSET $_offset';
    }
    return q;
  }

  String _generateQuery(String selectedColumns) {
    String q = _distinct ? ' DISTINCT' : '';
    q = ' $selectedColumns from $tableName';
    q = _getWhereQuery(q);
    q = _getOrderBy(q);
    q = _getGroupBy(q);
    q = _getLimitOffset(q);
    return q;
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

  /// Specify 'where' conditions in query.
  /// ```
  /// var userEloquent = UserEloquent();
  /// //get users where name is john
  /// userEloquent.where('name','john').get();
  ///
  /////get users where name is john and createdAt greater than   2022-05-03
  ///userEloquent.where('name','john').where('createdAt','2022-05-03', operator:Operator.greaterThan).get();
  ///
  /////get users where name is not john
  ///userEloquent.where('name','john',operator:Operator.notEqual).get();
  ///
  /////get users where name has 'j'
  ///userEloquent.where('name','%j%',operator:Operator.like).get();
  ///```
  Eloquent where(String columnName, String value,
      {Operator operator = Operator.equal}) {
    String? _operator;
    switch (operator) {
      case Operator.equal:
        _operator = '=';
        break;
      case Operator.greaterThan:
        _operator = '>';

        break;
      case Operator.lessThan:
        _operator = '<';

        break;
      case Operator.notEqual:
        _operator = '!=';

        break;
      case Operator.like:
        _operator = 'LIKE';

        break;
    }
    _wheres.add(_Where(
        columnName: columnName,
        value: value,
        operator: _operator,
        conjunction: 'and'));
    return this;
  }

  /// Sort rows in either descending or ascending order.
  /// ```
  ///var userEloquent = UserEloquent();
  ///
  /// // sort users by 'name' column
  ///userEloquent.orderBy('name').get();
  ///
  ///// sort users by 'name' column in descending order
  ///userEloquent.orderBy('name',sort:Sort.descending).get();
  ///```
  Eloquent orderBy(String? columnName, {Sort? sort}) {
    _orderBy = columnName;
    _sort = sort;
    return this;
  }

  /// Sort rows in descending order.
  /// ```
  /// var userEloquent = UserEloquent();
  /// // sort users by 'name' column in descending order
  /// userEloquent.orderByDesc('name').get();
  ///```
  Eloquent orderByDesc(String? columnName) {
    _orderBy = columnName;
    _sort = Sort.descending;
    return this;
  }

  /// Group rows by column.
  ///   ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // group users by 'name' column
  /// userEloquent.groupBy('name').get();
  /// ```
  Eloquent groupBy(String? columnName, {Sort? sort}) {
    _groupBy = columnName;
    _sort = sort;
    return this;
  }

  /// Group rows by column in descending order.

  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // group users by 'name' column
  /// userEloquent.groupByDesc('name').get();
  /// ```
  Eloquent groupByDesc(String? columnName) {
    _groupBy = columnName;
    _sort = Sort.descending;
    return this;
  }

  ///  Get latest row related to primary key. You can specify the column name.
  ///
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  ///  // Get latest user by 'id' which is primary key.
  /// userEloquent.latest().get();
  ///
  /// // Get latest user by 'name';
  /// userEloquent.latest(columnName:'name').get();
  /// ```
  Eloquent latest({String? columName}) {
    _orderBy = columName ?? getPrimaryColumn;
    _offset = 0;
    _sort = Sort.descending;
    _limit = 1;
    return this;
  }

  /// Limit the number of rows in result
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // get first user where name is like j
  /// userEloquent.where('name','%j%',operator:Operator.like).orderByDesc('name').take(1).get();
  /// ```
  Eloquent take(int? count) {
    _limit = count;
    return this;
  }

  /// Skip a given number of results.

  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// // skip 1 row and get next 10 users where name is like j
  /// userEloquent.where('name','%j%',operator:Operator.like).orderByDesc('name').skip(1).take(10).get();
  /// ```
  Eloquent skip(int? offset) {
    _offset = offset;
    return this;
  }

  /// Get unique column values.
  /// ```
  ///  var userEloquent = UserEloquent();
  ///// get unique rows related to column 'name'.
  ///userEloquent.distinct(['name']).get();
  ///```
  Eloquent distinct(List<String>? columnNames) {
    _selectedColumns = columnNames;
    _distinct = true;
    return this;
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
  Future<List<Map<String, Object?>>> all() async {
    Database _db = await getDatabase;
    String query = 'SELECT';
    _reset();
    query += _generateQuery('*');

    return await _db.rawQuery(query);
  }

  /// Final execution of query is performed by issuing this method.
  /// ```
  /// var userEloquent = UserEloquent();
  /// userEloquent.get();
  /// ```
  Future<List<Map<String, Object?>>?> get() async {
    String q = 'Select';
    q += _generateQuery(_getSelectedColumns() ?? '*');

    _reset();

    Database _db = await getDatabase;
    return await _db.rawQuery(q);
  }

  /// Specify columns to be only included in results.
  /// ```dart
  /// var userEloquent = UserEloquent();
  /// //return rows which have only 'name' column in results;
  ///userEloquent.select(['name']);
  ///```
  Eloquent select(List<String> selectedColumns) {
    _selectedColumns = selectedColumns;
    return this;
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
    _reset();
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
  Future<List<Map<String, Object?>>> search(String keyword,
      {List<String>? searchableColumns}) async {
    String _key = '%$keyword%';
    String q = 'Select';
    List<String>? _usedColumns;
    if (_wheres.isNotEmpty) {
      _usedColumns = _wheres.map((e) => e.columnName).toList();
      _wheres = [];
    }
    if (searchableColumns != null && searchableColumns.isNotEmpty) {
      for (var column in searchableColumns) {
        _wheres.add(_Where(
            columnName: column,
            value: _key,
            operator: 'LIKE',
            conjunction: 'or'));
      }
    } else {
      for (var column in columns) {
        if (_usedColumns != null && _usedColumns.contains(column)) {
          continue;
        }
        _wheres.add(_Where(
            columnName: column,
            value: _key,
            operator: 'LIKE',
            conjunction: 'or'));
      }
    }
    q += _generateQuery(_getSelectedColumns() ?? '*');
    _reset();
    Database _db = await getDatabase;
    return await _db.rawQuery(q);
  }

  /// Create a new row.
  /// ```dart
  /// var userEloquent = UserEloquent();
  ///
  /// userEloquent.create({'name':'John','password':'pass'});
  ///
  /// ```
  Future<int> create({required Map<String, Object?> values}) async {
    _reset();
    final db = await getDatabase;
    return await db.insert(tableName, values);
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
    _reset();
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
    _reset();
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
  Future<int> update(Map<String, Object?> values) async {
    String q = 'Update $tableName';
    for (var val in values.entries) {
      if (columns.contains(val.key)) {
        q += ' SET ${val.key} = "${val.value}"';
        if (val.key != values.keys.last) {
          q += ',';
        }
      }
    }
    q = _getWhereQuery(q);
    q = _getOrderBy(q);
    q = _getLimitOffset(q);
    _reset();
    final db = await getDatabase;
    return await db.rawUpdate(q);
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
  Future<int> delete() async {
    String query = 'Delete';
    _selectedColumns = [];
    _distinct = false;
    _orderBy = null;
    _groupBy = null;
    query += _generateQuery('');

    _reset();

    Database _db = await getDatabase;
    return await _db.rawDelete(query);
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

enum Sort { ascending, descending }

enum Operator { equal, greaterThan, lessThan, notEqual, like }

class _Where {
  String columnName;
  String value;
  String operator;
  String conjunction;
  _Where(
      {required this.columnName,
      required this.value,
      required this.operator,
      required this.conjunction});
}
