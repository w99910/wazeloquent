<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# WazEloquent

WazEloquent is designed to deal with database without writing custom querys on your own. This package is built on top of [Sqflite](https://github.com/tekartik/sqflite/tree/master/sqflite) package and inspired by [Laravel](https://laravel.com) eloquent.

## Features

- You don't need to create your own database class. Just interact with table by using `DB`'s methods such as `onCreate`, `onOpen`, `onConfigure`, `onUpgrade`, `onDowngrade`.
- Eazy to deal with table without writing query on your own.
- Laravel Eloquent alike methods.

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
    db.setDbVersion(1); // set db version
    db.setFileName('example.db'); // set file name
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
          'id': [ColumnType.idType, ColumnType.primaryKey],
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
          'id': [ColumnType.idType, ColumnType.primaryKey],
          'name': [ColumnType.stringType, ColumnType.notNull],
          'password': [ColumnType.stringType, ColumnType.notNull],
          'createdAt': [ColumnType.stringType, ColumnType.notNull],
          'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
        };
    });
  }
  ```

  Then use them like

  ```dart
  void main() {
    DB.instance.onCreate([UserEloquent.onCreate]);
    DB.instance.onOpen([UserEloquent.onOpen]);
    runApp(const MyApp());
  }
  ```

  Then you are ready to use eloquent.

## Usage

Available methods are as follows.

- [where](#where)
- [orderBy](#orderby)
- [orderByDesc](#orderbyDesc)
- [groupBy](#groupBy)
- [groupByDesc](#groupByDesc)
- [take](#take)
- [skip](#skip)
- [delete](#delete)
- [deleteBy](#deleteBy)
- [create](#create)
- [createIfNotExists](#createIfNotExists)
- [updateOrCreate](#updateOrCreate)
- [update](#update)
- [find](#find)
- [search](#search)
- [select](#select)
- [all](#all)
- [get](#get)
- [getDatabase](#getDatabase)

<br>

- ### where

  Specify conditions.

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

- ### take

  Limit the number of rows.

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

- ### select

  Select columns to be returned in results.

  ```dart
  var userEloquent = UserEloquent();

  // return rows which have only 'name' column in results;
  userEloquent.select(['name']);
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

- ### getDatabase
  A **static** method to get database instance.
  ```dart
  Database db = await UserEloquent.getDatabase;
  ```

## Additional information

> Check example [here](https://github.com/w99910/wazeloquent/tree/master/example)

This package is develped bc of my future flutter projects and it has only small features for now. I am planning to implement `relationship` features in future.
<br>
I would be really glad if this package helps you. Cheers.
