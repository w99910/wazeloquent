# WazEloquent ( Laravel Eloquent Wrapper For Flutter )

WazEloquent is designed to deal with database without writing custom querys on your own. This package is built on top of [Sqflite](https://github.com/tekartik/sqflite/tree/master/sqflite) package and inspired by [Laravel](https://laravel.com) eloquent.

## Features

- You don't need to create your own database class. Just interact with table by using `DB`'s methods such as `onCreate`, `onOpen`, `onConfigure`, `onUpgrade`, `onDowngrade`.
- Eazy to deal with table without writing query on your own.
- Laravel Eloquent alike methods.
- Managing [Relationships](RS_README.md)

## Getting started

- ### Extend eloquent and configure required methods

  e.g

  ```dart
  class UserEloquent extends Eloquent {
    @override
    // TODO: implement columns
    List<String> get columns => ['id','name','password','createdAt','updatedAt'];

    @override
    String get getPrimaryColumn => 'id';

    @override
    // TODO: implement tableName
    String get tableName => 'users';
  }
  ```

- ### Create table before using eloquent

  For creating table, you can easily do it by registering onOpen, OnCreate methods of `DB` class.
  For more information about creating table, please consult [sqflite documentaion.](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md)

  ```dart
  // lib/main.dart
  import 'package:wazeloquent/wazeloquent.dart' show DB;

  void main(){
    var db = DB.instance;
    db.setDbVersion(1); // optional: set db version, default: 1
    // db.setFilePath(path); // optional: set db path
    db.setFileName('example.db'); // optional: set file name, default: sqflite.db
    db.onCreate([
        Future(() {
          return (Database db, int) async {};
        }),
    ]);
    db.onOpen([
        Future((){
          return (Database db)async{
            // do something on Open db
        }),
    ]);

    db.onConfigure([]);
    db.onUpgrade([]);
    db.onDowngrade([]);

    runApp(const MyApp());
  }
  ```

  I would like to suggest you to have static variable in your eloquent. For example, see below.

  ```dart
  class UserEloquent extends Eloquent {
    static Future<Function(Database)> onOpen = Future(() {
        return (Database db) async {
        await DB.createTable(db, tableName: 'users',columns: {
          'id': [ColumnType.idType],
          'name': [ColumnType.stringType, ColumnType.notNull],
          'password': [ColumnType.stringType, ColumnType.notNull],
          'createdAt': [ColumnType.stringType, ColumnType.notNull],
          'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
        };
    });

    static Future<Function(Database, int)> onCreate = Future(() {
        return (Database db, int version) async {
        await DB.createTable(db, tableName: 'users',columns: {
          'id': [ColumnType.idType],
          'name': [ColumnType.stringType, ColumnType.notNull],
          'password': [ColumnType.stringType, ColumnType.notNull],
          'createdAt': [ColumnType.stringType, ColumnType.notNull],
          'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
        };
    });
  }
  ```

  Note that You can use sqflite table creating technique .i.e,

  ```dart
  await db.execute(
      'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
  ```

  Or You can use `DB.createTable()` method.

  Feel free to use whatever you feel like XD

  Then use them like

  ```dart
  void main() {
    DB.instance.onCreate([UserEloquent.onCreate]);
    DB.instance.onOpen([UserEloquent.onOpen]);
    runApp(const MyApp());
  }
  ```

  Then you are ready to use eloquent.

- ### Using existing db

  In order to use existing db, you can specify file path and file name. For example,

  ```dart
  import 'package:path_provider/path_provider.dart';

  var path = await getApplicationDocumentsDirectory();
  var dir = path.absolute.path + '/test';
  db.setFilePath(dir, shouldForceCreatePath: true); // Specify 'shouldForceCreatePath' to true for creating folder if not exist.
  db.setFileName('example.db');
  ```

## Usage

Available methods are as follows.

- [where](#where)
- [whereIn](#whereIn)
- [orderBy](#orderby)
- [orderByDesc](#orderbyDesc)
- [groupBy](#groupBy)
- [groupByDesc](#groupByDesc)
- [latest](#latest)
- [take](#take)
- [skip](#skip)
- [distinct](#distinct)
- [all](#all)
- [get](#get)
- [select](#select)
- [find](#find)
- [search](#search)
- [create](#create)
- [createIfNotExists](#createIfNotExists)
- [updateOrCreate](#updateOrCreate)
- [update](#update)
- [delete](#delete)
- [deleteBy](#deleteBy)
- [getDatabase](#getDatabase)

<br>

- ### where

  Specify 'where' conditions in query.

  > Always include `get()` method at the end of query. Otherwise query will not be executed.

  ```dart
  var userEloquent = UserEloquent();

  //get users where name is john
  userEloquent.where('name','john').get();

  //get users where name is john and createdAt greater than   2022-05-03
  userEloquent.where('name','john').where('createdAt','2022-05-03', operator:Operator.greaterThan).get();

  //get users where name is not john
  userEloquent.where('name','john',operator:Operator.notEqual).get();

  //get users where name has 'j'
  userEloquent.where('name','%j%',operator:Operator.like).get();
  ```

- ### whereIn

  Get all records of which column include any of the provided values.

  ```dart
  var userEloquent = UserEloquent();

  // get users where column `id` matches any of values [1,2,4]
  userEloquent.whereIn('id',[1,2,4]).get();
  ```

- ### orderBy

  Sort rows in either descending or ascending order.

  ```dart
  var userEloquent = UserEloquent();

  // sort users by 'name' column
  userEloquent.orderBy('name').get();

  // sort users by 'name' column in descending order
  userEloquent.orderBy('name',sort:Sort.descending).get();
  ```

- ### orderByDesc

  Sort rows in descending order.

  ```dart
  var userEloquent = UserEloquent();

  // sort users by 'name' column in descending order
  userEloquent.orderByDesc('name').get();
  ```

- ### groupBy

  Group rows by column.

  ```dart
  var userEloquent = UserEloquent();

  // group users by 'name' column
  userEloquent.groupBy('name').get();
  ```

- ### groupByDesc

  Group rows by column in descending order.

  ```dart
  var userEloquent = UserEloquent();

  // group users by 'name' column
  userEloquent.groupByDesc('name').get();
  ```

- ### latest

  Get latest row related to primary key. You can specify the column name.

  ```dart
  var userEloquent = UserEloquent();

  // Get latest user by 'id' which is primary key.
  userEloquent.latest().get();

  // Get latest user by 'name';
  userEloquent.latest(columnName:'name').get();
  ```

- ### take

  Limit the number of rows in result.

  ```dart
  var userEloquent = UserEloquent();

  // get first user where name is like j
  userEloquent.where('name','%j%',operator:Operator.like).orderByDesc('name').take(1).get();
  ```

- ### skip

  Skip a given number of results.

  ```dart
  var userEloquent = UserEloquent();

  // skip 1 row and get next 10 users where name is like j
  userEloquent.where('name','%j%',operator:Operator.like).orderByDesc('name').skip(1).take(10).get();
  ```

- ### distinct

  Get unique column values.

  ```dart
  var userEloquent = UserEloquent();

  // get unique rows related to column 'name'.
  userEloquent.distinct(['name']).get();

  ```

- ### all

  Return all rows from table.

  ```dart
  var userEloquent = UserEloquent();

  //similar to userEloquent.get() but no matter what options you specify, they will be ignored and all rows will be returned.
  userEloquent.all();

  //orderBy, limit will be ignored
  userEloquent.orderBy('name').limit(1).all();
  ```

- ### get

  Final execution of query is performed by issuing this method.

  ```dart
  var userEloquent = UserEloquent();

  userEloquent.get();
  ```

- ### select

  Select columns to be returned in results.

  ```dart
  var userEloquent = UserEloquent();

  // return rows which have only 'name' column in results;
  userEloquent.select(['name']);
  ```

- ### find

  Find row by primary key.

  ```dart
  var userEloquent = UserEloquent();

  // get user where primary key (id) is 1.
  userEloquent.find(1);
  ```

- ### search

  Search rows.

  ```dart
  var userEloquent = UserEloquent();

  // get rows where any column has word 'j'.
  userEloquent.search('j');

  // get rows where country has 'UK' and any other rows has 'j'.
  userEloquent.where('country','UK').search('j');

  //specify searchable columns
  userEloquent.search('j',searchableColumns:['name']);
  ```

- ### create

  Create a new row.

  ```dart
  var userEloquent = UserEloquent();

  userEloquent.create({'name':'John','password':'pass'});

  ```

- ### createIfNotExists

  Create a new row only if the value is not existed.

  ```dart
  var userEloquent = UserEloquent();

  // create user which name is john and password is pass only if name 'john' is not existed.
  userEloquent.createIfNotExists(check:{'name':'john'},create:{'password':'pass'});

  ```

- ### updateOrCreate

  Update data if exists and if not, create new row.

  ```dart
  var userEloquent = UserEloquent();

  // if row where name is john exists, update 'password' column. If not, create row where name is john and password is 'pass'.
  userEloquent.updateOrCreate(check:{'name':'john'},inserts:{'password':'pass'});
  ```

- ### update

  Update rows.

  ```dart
  var userEloquent = UserEloquent();

  // update name of all rows to 'john'.
  userEloquent.update({'name':'john'});

  // update name of rows where id = 1 to 1.
  userEloquent.where('id',1).update({'name':'john'});

  ```

- ### delete

  Delete rows from table

  ```dart
  var userEloquent = UserEloquent();

  // delete all rows from users
  userEloquent.delete();

  // delete rows where name has 'j' from users
  userEloquent.where('name','%j%',operator:Operator.like).delete();

  ```

- ### deleteBy

  Delete a row by primary key.

  ```dart
  var userEloquent = UserEloquent();

  // delete row where primary key is 1
  userEloquent.deleteBy(1);
  ```

- ### getDatabase
  A **static** method to get database instance.
  ```dart
  Database db = await UserEloquent.getDatabase;
  ```

## Models

It is not mandatory for your models to extend `Model` class. But extending `Model` class will provide some more methods to provide your model to interact with tables.

Let your model extend `Model` class.

```dart
class User extends Model{
  //configure required methods.
   Eloquent get eloquent => UserEloquent();

  dynamic get primaryValue => id; // primary value is the value of primary column.

  Map<String, Object?> get toJson => {
    'name': name,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String()
  };
}
```

Avaiable methods are

- [save](#saving-model)
- [update](#updating-model)
- [delete](#deleting-model)

- ### Saving Model

  Save the updated properties of your model.

  ```dart
  User user = User({name:'John',password:'pass'});
  user.name = 'Doe';
  await user.save(); // update the user's name to 'Doe' in table.
  ```

- ### Updating Model

  Other than `save` method, you can update the attributes of model by using `update` method.

  ```dart
  User user = User({name:'John',password:'pass'});
  await user.update({password:'newPassword'});
  ```

- ### Deleting Model

  Delete the model in table.

  ```dart
  User user = User();
  await user.delete();
  ```

## Relationships

Please read documention about relationships [here](RS_README.md).

## Bugs and issues

Please consider opening an issue in [issues tab](https://github.com/w99910/wazeloquent/issues) if you encounter a bug.

## Additional information

> Check example [here](https://github.com/w99910/wazeloquent/tree/master/example)

This package is developed to help developers' lives better and save time.
<br>
I would be really happy if this package helps you. Cheers 🎉🎉
