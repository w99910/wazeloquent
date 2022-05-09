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

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

- ### Extend Eloquent And Configure Necessary Methods

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
        await DB.createTable(db, tableName: 'users', columns: {
            'id': DB.idType,
            'name': DB.stringType,
            'password': DB.stringType,
            'createdAt': DB.stringType,
            'updatedAt': DB.stringType,
        });
        };
    });

    static Future<Function(Database, int)> onCreate = Future(() {
        return (Database db, int version) async {
        await DB.createTable(db, tableName: 'users', columns: {
            'id': DB.idType,
            'name': DB.stringType,
            'password': DB.stringType,
            'createdAt': DB.stringType,
            'updatedAt': DB.stringType,
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
- [groupBy](#groupBy)
- [limit](#limit)
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

<br>

- ### where

```dart
var userEloquent = UserEloqunet();

//get users where name is john
userEloquent.where('name','john').get();

//get users where name is john and createdAt greater than 2022-05-03
userEloquent.where('name','john').where('createdAt','2022-05-03',operator:Operator.greaterThan).get();

//get users where name is not john
userEloquent.where('name','john',operator:Operator.notEqual).get();

//get users where name has 'j'
userEloquent.where('name','%j%',operator:Operator.like).get();
```

- ### orderBy

- ### groupBy

- ### limit

- ### delete

- ### deleteBy

- ### create

- ### createIfNotExists

- ### update

- ### updateOrCreate

- ### find

- ### search

- ### select

- ### all

- ### get

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
