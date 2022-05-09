import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// class DBActions {
//   static const String setNull = 'SET NULL';
//   static const String setDefault = 'SET DEFAULT';
//   static const String restrict = 'RESTRICT';
//   static const String noAction = 'NO ACTION';
//   static const String cascade = 'CASCADE';
// }

enum DBActions { setNull, setDefault, restrict, noAction, cascade }

class ColumnType {
  static const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const notNull = 'NOT NULL';
  static defaultValue(value) => 'DEFAULT "$value"';
  static const primaryKey = 'PRIMARY KEY';
  static const boolType = 'BOOLEAN';
  static const integerType = 'INTEGER';
  static const stringType = 'TEXT';
}

class DB {
  static String fileName = 'sqflite.db';
  static int version = 1;

  static String getAction(DBActions action) {
    switch (action) {
      case DBActions.cascade:
        return 'CASCADE';
      case DBActions.noAction:
        return 'NO ACTION';
      case DBActions.setNull:
        return 'SET NULL';
      case DBActions.setDefault:
        return 'SET DEFAULT';
      case DBActions.restrict:
        return 'RESTRICT';
    }
  }

  static String foreign({
    required String foreignKey,
    required String parentKey,
    required String parentTable,
    required String type,
    DBActions? onUpdate,
    DBActions? onDelete,
  }) {
    String query = '$foreignKey $type REFERENCES $parentTable($parentKey)';
    if (onUpdate != null) {
      query += ' ON UPDATE ' + getAction(onUpdate) + '\n';
    }
    if (onDelete != null) {
      query += ' ON DELETE ' + getAction(onDelete) + '\n';
    }
    return query;
  }

  static final DB instance = DB._init();
  DB._init();

  static List<Future<Function(Database, int)>> _onCreate = [];
  static List<Future<Function(Database)>> _onOpen = [];
  static List<Future<Function(Database)>> _onConfigure = [];
  static List<Future<Function(Database, int, int)>> _onUpgrade = [];
  static List<Future<Function(Database, int, int)>> _onDowngrade = [];

  static Database? _database;

  void onCreate(List<Future<Function(Database, int)>> fn) {
    _onCreate.addAll(fn);
  }

  void onOpen(List<Future<Function(Database)>> fn) {
    _onOpen.addAll(fn);
  }

  void onConfigure(List<Future<Function(Database)>> fn) {
    _onConfigure.addAll(fn);
  }

  void onUpgrade(List<Future<Function(Database, int, int)>> fn) {
    _onUpgrade.addAll(fn);
  }

  void onDowngrade(List<Future<Function(Database, int, int)>> fn) {
    _onDowngrade.addAll(fn);
  }

  void setFileName(String name) {
    fileName = name;
  }

  void setDbVersion(int ver) {
    version = ver;
  }

  Future<Database> get database async => await getDB();

  Future<Database> getDB() async {
    if (_database != null) return _database!;
    _database = await _initDB(fileName: fileName);
    return _database!;
  }

  Future<void> reinitialiseDB() async {
    _database = await _initDB(fileName: fileName);
  }

  static Future createTable(Database db,
      {required String tableName,
      required Map<String, Object?> columns}) async {
    var string = '';
    columns.forEach((key, value) {
      if (value is Function) {
        string += value();
      } else if (value is List<String>) {
        string += key;
        for (var type in value) {
          string += ' $type';
        }
      } else {
        string += '$key $value';
      }
      if (key != columns.entries.last.key) {
        string += ',';
      }
    });
    await db.execute('CREATE TABLE IF NOT EXISTS $tableName (' + string + ' )');
  }

  Future<Database> _initDB({required String fileName}) async {
    final dbPath = Platform.isAndroid
        ? await getDatabasesPath()
        : (await getApplicationDocumentsDirectory()).toString();
    final path = join(dbPath + fileName);
    if (!await Directory(dirname(path)).exists()) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (e) {
        // print(e);
      }
    }
    return await openDatabase(path, version: version,
        onCreate: (Database db, int version) async {
      for (var fn in _onCreate) {
        Function.apply(await fn, [db, version]);
      }
    }, onOpen: (Database db) async {
      for (var fn in _onOpen) {
        Function.apply(await fn, [db]);
      }
    }, onConfigure: (Database db) async {
      for (var fn in _onConfigure) {
        Function.apply(await fn, [db]);
      }
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      for (var fn in _onUpgrade) {
        Function.apply(await fn, [db, oldVersion, newVersion]);
      }
    }, onDowngrade: (Database db, int oldVersion, int newVersion) async {
      for (var fn in _onDowngrade) {
        Function.apply(await fn, [db, oldVersion, newVersion]);
      }
    });
  }
}
