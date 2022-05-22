import 'package:wazeloquent/wazeloquent.dart';

class CountryEloquent extends Eloquent {
  @override
  List<String> get columns => ['id', 'name', 'createdAt', 'updatedAt'];

  @override
  String get getPrimaryColumn => 'id';

  @override
  String get tableName => 'countries';

  static Future<Function(Database)> onOpen = Future(() {
    return (Database db) async {
      await DB.createTable(db, tableName: 'countries', columns: {
        'id': [ColumnType.idType],
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });

      await DB.createTable(db, tableName: 'country_user', columns: {
        'id': [ColumnType.idType],
        'countryId': DB.foreign(
            foreignKey: 'countryId',
            parentKey: 'id',
            parentTable: 'countries',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'userId': DB.foreign(
            foreignKey: 'userId',
            parentKey: 'id',
            parentTable: 'users',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });

  static Future<Function(Database, int)> onCreate = Future(() {
    return (Database db, int version) async {
      await DB.createTable(db, tableName: 'countries', columns: {
        'id': [ColumnType.idType],
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });

      await DB.createTable(db, tableName: 'country_user', columns: {
        'id': [ColumnType.idType],
        'countryId': DB.foreign(
            foreignKey: 'countryId',
            parentKey: 'id',
            parentTable: 'countries',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'userId': DB.foreign(
            foreignKey: 'userId',
            parentKey: 'id',
            parentTable: 'users',
            onDelete: DBActions.cascade,
            type: ColumnType.integerType),
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  });
}
