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
    if (_limit != null) {
      q += ' LIMIT ';
      q += _offset != null ? '$_offset, $_limit' : '$_limit';
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

  Eloquent select(List<String> selectedColumns) {
    _selectedColumns = selectedColumns;
    return this;
  }

  Future<List<Map<String, Object?>>?> get() async {
    String q = 'Select';
    q += _generateQuery(_getSelectedColumns() ?? '*');

    _reset();

    Database _db = await getDatabase;
    return await _db.rawQuery(q);
  }

  Eloquent distinct(List<String>? columnNames) {
    _selectedColumns = columnNames;
    _distinct = true;
    return this;
  }

  Eloquent limit(int? limit, {int? offset}) {
    _limit = limit;
    _offset = offset;
    return this;
  }

  Eloquent orderBy(String? columnName, {Sort? sort}) {
    _orderBy = columnName;
    _sort = sort;
    return this;
  }

  Eloquent orderByDesc(String? columnName) {
    _orderBy = columnName;
    _sort = Sort.descending;
    return this;
  }

  Eloquent groupBy(String? columnName, {Sort? sort}) {
    _groupBy = columnName;
    _sort = sort;
    return this;
  }

  Eloquent groupByDesc(String? columnName) {
    _groupBy = columnName;
    _sort = Sort.descending;
    return this;
  }

  /// returns the number of changes made.
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

  Future<List<Map<String, Object?>>?> runQuery(String query) async {
    Database _db = await getDatabase;
    return await _db.rawQuery(query);
  }

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

  Future<Map<String, Object?>?> find(primaryKeyValue) async {
    Database _db = await getDatabase;
    var results = await _db.query(
      tableName,
      columns: columns,
      where: getPrimaryColumn + ' = ?',
      whereArgs: [primaryKeyValue],
    );
    if (results.isNotEmpty) {
      return results[0];
    }
    return null;
  }

  Future<List<Map<String, Object?>>> search(String keyword,
      {List<String>? searchableColumns}) async {
    String _key = '%$keyword%';
    String q = 'Select';
    List<String>? _usedColumns;
    if (_wheres.isNotEmpty) {
      _usedColumns = _wheres.map((e) => e.columnName).toList();
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
    Database _db = await getDatabase;
    return await _db.rawQuery(q);
  }

  Future<int> deleteBy(value) async {
    Database _db = await getDatabase;
    return await _db.delete(
      tableName,
      where: getPrimaryColumn + ' = ?',
      whereArgs: [value],
    );
  }

  Future<List<Map<String, Object?>>> all() async {
    Database _db = await getDatabase;
    String query = 'SELECT';
    _reset();
    query += _generateQuery('*');

    return await _db.rawQuery(query);
  }

  Future<int> create({required Map<String, Object?> values}) async {
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

  Future<int?> createIfNotExists(
      {required Map<String, Object?> check,
      required Map<String, Object?> create}) async {
    final db = await getDatabase;
    List result = await _where(check);
    if (result.isNotEmpty) {
      return int.tryParse(result.first[getPrimaryColumn]);
    }
    create.addAll(check);
    return await db.insert(tableName, create);
  }

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
    return await db.insert(tableName, {...check, ...inserts});
  }

  ///returns the number of changes made.
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
    final db = await getDatabase;
    return await db.rawUpdate(q);
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
