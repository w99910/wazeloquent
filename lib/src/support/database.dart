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

enum _DBProcess { onCreate, onOpen, onConfigure, onUpgrade, onDowngrade }

class ColumnType {
  static const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const notNull = 'NOT NULL';
  static defaultValue(value) => 'DEFAULT "$value"';
  static const primaryKey = 'PRIMARY KEY';
  static const boolType = 'BOOLEAN';
  static const integerType = 'INTEGER';
  static const stringType = 'TEXT';

  static String enumToString(List<String> types) {
    if (types.isEmpty) {
      return '';
    }
    var string = '';
    for (var type in types) {
      string += ' $type';
    }
    return string;
  }
}

class DB {
  static String _fileName = 'wazeloquent.db';
  static int _version = 1;
  static String? _filePath;
  static bool _shouldForceCreatePath = false;

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

  final List<Future<Function(Database, int)>> _onCreate = [];
  final List<Future<Function(Database)>> _onOpen = [];
  final List<Future<Function(Database)>> _onConfigure = [];
  final List<Future<Function(Database, int, int)>> _onUpgrade = [];
  final List<Future<Function(Database, int, int)>> _onDowngrade = [];

  final Map<_DBProcess, List<String>> _queries = {};

  static Database? _database;

  /// Executes when creating database. This method should be called before using eloquent.
  /// ```
  /// DB.instance.onCreate([
  ///       Future(() {
  ///         return (Database db, int) async {};
  ///       }),
  ///   ]);
  ///
  /// //Or
  /// DB.instance.onCreate([UserEloquent.onCreate]);
  /// ```
  void onCreate(List<Future<Function(Database, int)>> fn) {
    _onCreate.addAll(fn);
  }

  /// Executes when opening database. This method should be called before using eloquent.
  /// ```
  /// DB.instance.onOpen([
  ///       Future(() {
  ///         return (Database db) async {};
  ///       }),
  ///   ]);
  ///
  /// //Or
  /// DB.instance.onOpen([UserEloquent.onOpen]);
  /// ```
  void onOpen(List<Future<Function(Database)>> fn) {
    _onOpen.addAll(fn);
  }

  /// Executes when creating database. This method should be called before using eloquent.
  /// ```
  /// DB.instance.onConfigure([
  ///       Future(() {
  ///         return (Database db) async {};
  ///       }),
  ///   ]);
  ///
  /// //Or
  /// DB.instance.onConfigure([UserEloquent.onConfigure]);
  /// ```
  void onConfigure(List<Future<Function(Database)>> fn) {
    _onConfigure.addAll(fn);
  }

  /// Executes when creating database. This method should be called before using eloquent.
  /// ```
  /// DB.instance.onUpgrade([
  ///       Future(() {
  ///         return (Database db, int oldversion,int newversion) async {};
  ///       }),
  ///   ]);
  ///
  /// //Or
  /// DB.instance.onUpgrade([UserEloquent.onUpgrade]);
  /// ```
  void onUpgrade(List<Future<Function(Database, int, int)>> fn) {
    _onUpgrade.addAll(fn);
  }

  /// Executes when creating database. This method should be called before using eloquent.
  /// ```
  /// DB.instance.onDowngrade([
  ///       Future(() {
  ///         return (Database db, int oldversion,int newversion) async {};
  ///       }),
  ///   ]);
  ///
  /// //Or
  /// DB.instance.onDowngrade([UserEloquent.onDowngrade]);
  /// ```
  void onDowngrade(List<Future<Function(Database, int, int)>> fn) {
    _onDowngrade.addAll(fn);
  }

  /// Set file name. This method should be called before using eloquent.
  void setFilePath(String path, {bool shouldForceCreatePath = false}) {
    _filePath = path;
    _shouldForceCreatePath = shouldForceCreatePath;
  }

  /// Set file name. This method should be called before using eloquent.
  void setFileName(String name) {
    _fileName = name;
  }

  /// Set db version. Set file name. This method should be called before using eloquent.
  void setDbVersion(int ver) {
    _version = ver;
  }

  Future<Database> get database async => await getDB();

  Future<Database> getDB() async {
    if (_database != null) return _database!;
    _database = await _initDB(fileName: _fileName);
    return _database!;
  }

  /// Create table using helper method
  ///
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

  static Future addColumn(
    String columnName, {
    required String tableName,
    required Database db,
    required List<String> types,
    DBActions? onUpdate,
    DBActions? onDelete,
  }) async {
    var type = ColumnType.enumToString(types);
    String query = 'ALTER TABLE $tableName ADD $columnName $type';
    if (onUpdate != null) {
      query += ' ON UPDATE ' + getAction(onUpdate) + '\n';
    }
    if (onDelete != null) {
      query += ' ON DELETE ' + getAction(onDelete) + '\n';
    }
    await db.execute(query);
  }

  Future<Database> _initDB({required String fileName}) async {
    String? dbPath;
    if (_filePath != null) {
      if (!Directory(_filePath!).existsSync()) {
        if (!_shouldForceCreatePath) {
          throw Exception('Folder not found to create db.');
        }
        await Directory(_filePath!).create(recursive: true);
      }
      dbPath = _filePath;
    } else {
      dbPath = Platform.isAndroid
          ? await getDatabasesPath()
          : (await getApplicationDocumentsDirectory()).absolute.path + '/';
    }

    final path = join(dbPath! + fileName);
    if (!await Directory(dirname(path)).exists()) {
      await Directory(dirname(path)).create(recursive: true);
    }
    return await openDatabase(path, version: _version,
        onCreate: (Database db, int version) async {
      for (var fn in _onCreate) {
        Function.apply(await fn, [db, version]);
      }
      if (_queries.containsKey(_DBProcess.onCreate)) {
        List<String> queries = _queries[_DBProcess.onCreate]!;
        if (queries.isNotEmpty) {
          for (var query in queries) {
            await db.execute(query);
          }
        }
      }
    }, onOpen: (Database db) async {
      for (var fn in _onOpen) {
        Function.apply(await fn, [db]);
      }
      if (_queries.containsKey(_DBProcess.onOpen)) {
        List<String> queries = _queries[_DBProcess.onOpen]!;
        if (queries.isNotEmpty) {
          for (var query in queries) {
            await db.execute(query);
          }
        }
      }
    }, onConfigure: (Database db) async {
      for (var fn in _onConfigure) {
        Function.apply(await fn, [db]);
      }
      if (_queries.containsKey(_DBProcess.onConfigure)) {
        List<String> queries = _queries[_DBProcess.onConfigure]!;
        if (queries.isNotEmpty) {
          for (var query in queries) {
            await db.execute(query);
          }
        }
      }
    }, onUpgrade: (Database db, int oldVersion, int newVersion) async {
      for (var fn in _onUpgrade) {
        Function.apply(await fn, [db, oldVersion, newVersion]);
      }
      if (_queries.containsKey(_DBProcess.onUpgrade)) {
        List<String> queries = _queries[_DBProcess.onUpgrade]!;
        if (queries.isNotEmpty) {
          for (var query in queries) {
            await db.execute(query);
          }
        }
      }
    }, onDowngrade: (Database db, int oldVersion, int newVersion) async {
      for (var fn in _onDowngrade) {
        Function.apply(await fn, [db, oldVersion, newVersion]);
      }
      if (_queries.containsKey(_DBProcess.onDowngrade)) {
        List<String> queries = _queries[_DBProcess.onDowngrade]!;
        if (queries.isNotEmpty) {
          for (var query in queries) {
            await db.execute(query);
          }
        }
      }
    });
  }
}
