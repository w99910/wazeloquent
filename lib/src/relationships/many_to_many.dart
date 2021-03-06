import 'package:wazeloquent/wazeloquent.dart';

mixin ManyToMany on RelationshipModel {
  String? _initialForeignKey, _initialParentKey, _initialTable;
  String? _relatedForeignKey, _relatedParentKey, _relatedTable;
  String? _pivotTable;

  /// Define many-to-many relationship.
  /// Pivot table name should be in alphabetical order.
  /// For example, `class_student` or `role_user`.
  /// If not in alphabetical order, you must specify pivot table.
  Future<ManyToMany> belongsToMany(String relatedTable,
      {String? pivotTable}) async {
    var database = await eloquent.getDatabase;
    var tables = await database.rawQuery(
        'SELECT name FROM sqlite_schema WHERE type = "table" AND name NOT LIKE "sqlite_%"');
    if (pivotTable == null) {
      var table1 = relatedTable.substring(0, relatedTable.length - 3);
      var table2 = tableName.substring(0, tableName.length - 3);
      if (table1.compareTo(table2) > 0) {
        var temp = table1;
        table1 = table2;
        table2 = temp;
      }

      var regexExp = '($table1).*($table2).*';
      for (var table in tables) {
        var matches = RegExp(regexExp).firstMatch(table['name'].toString());
        if (matches != null) {
          pivotTable = matches[0];
        }
      }
    } else {
      if (tables.where((element) => element['name'] == pivotTable).isEmpty) {
        throw Exception('There is no such table');
      }
    }

    _pivotTable = pivotTable;

    var foreignKeys = await eloquent.getForeignKeys(table: pivotTable);

    var initial = foreignKeys.where((element) => element['table'] == tableName);
    if (initial.isEmpty) {
      throw Exception(
          'There is no foreign key in $_pivotTable table which references to $tableName. \n Consider checking your database setup');
    }
    var _initial = initial.first;
    _initialForeignKey = _initial['from'];
    _initialParentKey = _initial['to'];
    _initialTable = _initial['table'];
    var related =
        foreignKeys.where((element) => element['table'] == relatedTable);
    if (related.isEmpty) {
      throw Exception(
          'There is no foreign key in $_pivotTable table which references to $relatedTable. \n Consider checking your database setup');
    }

    var _related = related.first;

    _relatedForeignKey = _related['from'];
    _relatedParentKey = _related['to'];
    _relatedTable = relatedTable;

    // Generate Query
    query =
        '$_relatedTable table1 JOIN $_pivotTable pivot ON pivot.$_relatedForeignKey = table1.$_relatedParentKey JOIN $_initialTable table2 ON table2.$_initialParentKey = pivot.$_initialForeignKey WHERE table2.${eloquent.getPrimaryColumn} = "$primaryValue"';

    return this;
  }

  /// Create a record in pivot table and return the id of last inserted row.
  /// ```
  /// var classroom = Class();
  ///var student = Student();
  ///var query = await classroom.getStudents();
  ///
  ///await query.attach(student);
  ///```
  Future<int> attach(RelationshipModel model,
      {Map<String, Object?>? extras}) async {
    if (query == null) {
      throw Exception('cannot query without relationship');
    }

    if (_pivotTable == null) {
      throw Exception('Unknown Pivot table');
    }
    var initialParentValue = primaryValue;

    var relatedParentValue = model.primaryValue;

    Map<String, Object?> values = {
      "$_initialForeignKey": initialParentValue,
      "$_relatedForeignKey": relatedParentValue,
      if (extras != null) ...extras,
    };

    var database = await eloquent.getDatabase;
    return await database.insert(_pivotTable!, values);
  }

  /// Create records in pivot table and return a list of added indexes.
  /// ```
  /// var classroom = Class();
  /// var query = await classroom.getStudents();
  ///
  ///await query.attachMany([Student(),Student()]);
  ///```
  Future<List<int>> attachMany(List<RelationshipModel> models,
      {Map<String, Object?>? extras}) async {
    if (query == null) {
      throw Exception('cannot query without relationship');
    }

    if (_pivotTable == null) {
      throw Exception('Unknown Pivot table');
    }

    if (models.isEmpty) {
      throw Exception('Empty models');
    }

    var initialParentValue = primaryValue;
    var database = await eloquent.getDatabase;

    List<int> indexes = [];
    for (var model in models) {
      var relatedParentValue = model.primaryValue;

      Map<String, Object?> values = {
        "$_initialForeignKey": initialParentValue,
        "$_relatedForeignKey": relatedParentValue,
        if (extras != null) ...extras,
      };
      indexes.add(await database.insert(_pivotTable!, values));
    }

    return indexes;
  }

  /// Delete related row or rows in pivot table and return the number of changes made.
  /// ```
  /// var student = Student();
  /// var classQuery = await student.getClasses();
  ///
  ///// Delete single row in pivot table
  /// await classQuery.detach(model:Class());
  ///
  ///// delete all related rows in pivot table
  /// await classQuery.detach();
  /// ```
  Future<int> detach({RelationshipModel? model}) async {
    if (query == null) {
      throw Exception('cannot query without relationship');
    }
    var initialParentValue = primaryValue;
    Object? relatedParentValue;
    if (model != null) {
      relatedParentValue = model.primaryValue;
    }
    String q =
        'DELETE FROM $_pivotTable WHERE $_initialForeignKey = $initialParentValue';
    if (relatedParentValue != null) {
      q += ' AND $_relatedForeignKey = $relatedParentValue';
    }
    var database = await eloquent.getDatabase;
    return await database.rawDelete(q);
  }
}
