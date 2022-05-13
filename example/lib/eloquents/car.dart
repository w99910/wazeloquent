import 'package:example/models/car.dart';
import 'package:wazeloquent/wazeloquent.dart';

class CarEloquent extends Eloquent {
  @override
  List<String> get columns => ['id', 'name', 'createdAt', 'updatedAt'];

  @override
  String get getPrimaryColumn => 'id';

  @override
  String get tableName => 'cars';

  user(String id) async {
    return await where('id', id).belongsTo('users');
  }

  static Future<Function(Database)> onOpen = Future(() {
    return (Database db) async {
      await DB.createTable(db, tableName: 'cars', columns: {
        'id': [ColumnType.idType],
        'user_id': DB.foreign(
            foreignKey: 'user_id',
            parentKey: 'id',
            parentTable: 'users',
            type: ColumnType.integerType,
            onDelete: DBActions.cascade),
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });

  static Future<Function(Database, int)> onCreate = Future(() {
    return (Database db, int version) async {
      await DB.createTable(db, tableName: 'cars', columns: {
        'id': [ColumnType.idType],
        'user_id': DB.foreign(
            foreignKey: 'user_id',
            parentKey: 'id',
            parentTable: 'users',
            type: ColumnType.integerType,
            onDelete: DBActions.cascade),
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });
}
