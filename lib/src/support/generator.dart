import 'package:wazeloquent/src/enums/operator.dart';
import 'package:wazeloquent/src/enums/sort.dart';

abstract class Generator {
  List<String> get columns;

  String get tableName;

  String get getPrimaryColumn;

  String? _orderBy;

  String? _groupBy;

  bool _distinct = false;

  Sort? _sort;

  int? _offset;

  int? _limit;

  // List<Function?> _withs = [];

  List<String>? _selectedColumns;

  List<_Where> _wheres = [];

  Future<List<Map<String, Object?>>> get();

  Future<List<Map<String, Object?>>> all();

  Future<Map<String, Object?>?> first() async {
    var values = await get();
    if (values.isEmpty) {
      return null;
    }
    return values.first;
  }

  Future<int> create(Map<String, Object?> values);

  Future<int> update(Map<String, Object?> values);

  Future<int> delete();

  Future<List<Map<String, Object?>>> search(String keyword,
      {List<String>? searchableColumns});

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
    throw UnimplementedError();
  }

  Future<int?> createIfNotExists(
      {required Map<String, Object?> check,
      required Map<String, Object?> create}) async {
    throw UnimplementedError();
  }

  Future<Map<String, Object?>?> find(primaryKeyValue) async {
    throw UnimplementedError();
  }

  resetAll() {
    _orderBy = null;
    resetOrderBy();
    resetGroupBy();
    resetDistinct();
    resetSort();
    resetOffset();
    resetLimit();
    resetSelectedColunns();
    // resetWiths();
    resetWheres();
  }

  resetOrderBy() {
    _orderBy = null;
  }

  resetGroupBy() {
    _groupBy = null;
  }

  resetDistinct() {
    _distinct = false;
  }

  resetSort() {
    _sort = null;
  }

  resetOffset() {
    _offset = null;
  }

  resetLimit() {
    _limit = null;
  }

  resetSelectedColunns() {
    _selectedColumns = null;
  }

  // resetWiths() {
  //   _withs = [];
  // }

  resetWheres() {
    _wheres = [];
  }

  List<_Where> getWhereColumns() {
    return _wheres;
  }

  String? getSelectedColumns({String? table}) {
    if (table != null) {
      table = table + '.';
    }
    return _toString(_selectedColumns, prefix: table);
  }

  List<String>? getSelectedColumnAsArray() {
    return _selectedColumns;
  }

  String? _toString(List<String>? values, {String? prefix}) {
    String? val;
    if (values != null && values.isNotEmpty) {
      String temp = '';
      for (var col in _selectedColumns!.asMap().entries) {
        temp += prefix != null ? prefix + col.value : col.value;
        if (col.key != _selectedColumns!.length - 1) {
          temp += ',';
        }
      }
      val = temp;
    }
    return val;
  }

  String _getWhereQuery(String q, {String? table}) {
    if (_wheres.isNotEmpty) {
      if (!q.contains('WHERE')) {
        q += ' WHERE';
      } else {
        q += ' AND';
      }
      table ??= tableName;
      var whereAnd =
          _wheres.where((element) => element.conjunction == 'and').toList();
      var whereOr =
          _wheres.where((element) => element.conjunction == 'or').toList();
      for (var where in whereAnd.asMap().entries) {
        String prefix =
            where.value.operator == 'IN' || where.value.operator == 'NOT IN'
                ? '('
                : '"';
        String postfix =
            where.value.operator == 'IN' || where.value.operator == 'NOT IN'
                ? ')'
                : '"';
        q +=
            ' $table.${where.value.columnName} ${where.value.operator} $prefix${where.value.value}$postfix';
        if (where.key != _wheres.length - 1) {
          q += ' ${where.value.conjunction}';
        }
      }
      for (var where in whereOr.asMap().entries) {
        String prefix =
            where.value.operator == 'IN' || where.value.operator == 'NOT IN'
                ? '('
                : '"';
        String postfix =
            where.value.operator == 'IN' || where.value.operator == 'NOT IN'
                ? ')'
                : '"';
        if (where.key == 0) {
          q += ' (';
        }
        q +=
            ' $table.${where.value.columnName} ${where.value.operator} $prefix${where.value.value}$postfix';
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
    _limit = _limit ?? -1;
    q += ' LIMIT $_limit';
    if (_offset != null) {
      q += ' OFFSET $_offset';
    }
    return q;
  }

  String generateQuery(String prefix, {String? table}) {
    String q = _distinct ? ' DISTINCT' : '';
    q = prefix;
    q = _getWhereQuery(q, table: table);
    q = _getOrderBy(q);
    q = _getGroupBy(q);
    q = _getLimitOffset(q);
    return q;
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
  Generator where(String columnName, value,
      {Operator operator = Operator.equal, String? conjuncation}) {
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

      case Operator.notLike:
        _operator = 'NOT LIKE';
        break;

      case Operator.inArray:
        if (value is! List) {
          throw Exception('Value must be List type.');
        }
        String temp = '';
        List values = value;
        values.asMap().entries.forEach((element) {
          temp += '"${element.value.toString()}"';
          if (element.key != values.length - 1) {
            temp += ',';
          }
        });
        value = temp;
        _operator = 'IN';
        break;
      case Operator.notInArray:
        if (value is! List) {
          throw Exception('Value must be List type.');
        }
        String temp = '';
        List values = value;
        values.asMap().entries.forEach((element) {
          temp += '"${element.value.toString()}"';
          if (element.key != values.length - 1) {
            temp += ',';
          }
        });
        value = temp;
        _operator = 'NOT IN';
        break;
    }
    _wheres.add(_Where(
        columnName: columnName,
        value: value.toString(),
        operator: _operator,
        conjunction: conjuncation ?? 'and'));
    return this;
  }

  /// Get all records of which `columnName` include any of `values`.
  /// ```
  /// var userEloquent = UserEloquent();
  ///
  /// // get users where column `id` matches any of values [1,2,4]
  /// userEloquent.whereIn('id',[1,2,4]).get();
  /// ```
  Generator whereIn(String columnName, List values) {
    if (!columns.contains(columnName)) {
      throw Exception('Column "$columnName" not found');
    }
    return where(columnName, values, operator: Operator.inArray);
  }

  /// Get all records of which `columnName` does not include any of `values`.
  /// ```
  /// var userEloquent = UserEloquent();
  ///
  /// // get users where column `id` does not equal any of values [1,2,4]
  /// userEloquent.whereNotIn('id',[1,2,4]).get();
  /// ```
  Generator whereNotIn(String columnName, List values) {
    if (!columns.contains(columnName)) {
      throw Exception('Column "$columnName" not found');
    }
    return where(columnName, values, operator: Operator.notInArray);
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
  Generator orderBy(String? columnName, {Sort? sort}) {
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
  Generator orderByDesc(String? columnName) {
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
  Generator groupBy(String? columnName, {Sort? sort}) {
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
  Generator groupByDesc(String? columnName) {
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
  Generator latest({String? columName}) {
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
  Generator take(int? count) {
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
  Generator skip(int? offset) {
    _offset = offset;
    return this;
  }

  /// Get unique column values.
  /// ```
  ///  var userEloquent = UserEloquent();
  ///// get unique rows related to column 'name'.
  ///userEloquent.distinct(['name']).get();
  ///```
  Generator distinct(List<String>? columnNames) {
    _selectedColumns = columnNames;
    _distinct = true;
    return this;
  }

  /// Specify columns to be only included in results.
  /// ```dart
  /// var userEloquent = UserEloquent();
  /// //return rows which have only 'name' column in results;
  ///userEloquent.select(['name']);
  ///```
  Generator select(List<String> selectedColumns) {
    _selectedColumns = selectedColumns;
    return this;
  }
}

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
