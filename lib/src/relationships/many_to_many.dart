import 'package:wazeloquent/wazeloquent.dart';

mixin ManyToMany on RelationshipModel {
  Future<RelationshipModel> belongsToMany(String relatedTable,
      {String? pivotTable,
      String? foreignKeyOfParent,
      String? foreignKeyOfChild}) async {
    String? q;
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

    var foreignKeys = await eloquent.getForeignKeys(table: pivotTable);
    var initial =
        foreignKeys.where((element) => element['table'] == tableName).first;
    var initialForeignKey = initial['from'];
    var initialParentKey = initial['to'];
    var initialTable = initial['table'];
    var related =
        foreignKeys.where((element) => element['table'] == relatedTable).first;
    var relatedForeignKey = related['from'];
    var relatedParentKey = related['to'];
    print([initialForeignKey, initialParentKey, initialTable]);
    print([relatedForeignKey, relatedParentKey, relatedTable]);
    return this;
  }

  associate() {}
}
