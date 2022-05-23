import 'package:wazeloquent/wazeloquent.dart';

class StudentEloquent extends Eloquent {
  @override
  List<String> get columns => ['id', 'name', 'createdAt', 'updatedAt'];

  @override
  String get getPrimaryColumn => 'id';

  @override
  String get tableName => 'students';

  static Future<Function(Database)> onOpen = Future(() {
    return (Database db) async {
      await DB.createTable(db, tableName: 'students', columns: {
        'id': [ColumnType.idType],
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });

  static Future<Function(Database, int)> onCreate = Future(() {
    return (Database db, int version) async {
      await DB.createTable(db, tableName: 'students', columns: {
        'id': [ColumnType.idType],
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });
}
