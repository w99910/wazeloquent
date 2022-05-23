import 'package:wazeloquent/wazeloquent.dart';

class ClassEloquent extends Eloquent {
  @override
  List<String> get columns => ['id', 'name', 'createdAt', 'updatedAt'];

  @override
  String get getPrimaryColumn => 'id';

  @override
  String get tableName => 'classes';

  static Future<Function(Database)> onOpen = Future(() {
    return (Database db) async {
      await DB.createTable(db, tableName: 'classes', columns: {
        'id': [ColumnType.idType],
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });

      await DB.createTable(db, tableName: 'class_student', columns: {
        'id': [ColumnType.idType],
        'classId': DB.foreign(
            foreignKey: 'classId',
            parentKey: 'id',
            parentTable: 'classes',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'studentId': DB.foreign(
            foreignKey: 'studentId',
            parentKey: 'id',
            parentTable: 'students',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });

  static Future<Function(Database, int)> onCreate = Future(() {
    return (Database db, int version) async {
      await DB.createTable(db, tableName: 'classes', columns: {
        'id': [ColumnType.idType],
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });

      await DB.createTable(db, tableName: 'class_student', columns: {
        'id': [ColumnType.idType],
        'classId': DB.foreign(
            foreignKey: 'classId',
            parentKey: 'id',
            parentTable: 'classes',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'studentId': DB.foreign(
            foreignKey: 'studentId',
            parentKey: 'id',
            parentTable: 'students',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });
}
