# Relationships

Supported relationship types are

- [one-to-one](#one-to-one)
- [one-to-many](#one-to-many)
- [many-to-many](#many-to-many)

### Getting StartREADME.mded

- Enable foreign key options in db.

```dart
 db.onConfigure([
    Future(() {
      return (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      };
    })
  ]);
```

- Extend `RelationshipModel` or replace `Model` with `RelationshipModel` class if your model is previously extending `Model` class.

```dart
class User extends RelationshipModel {}
```

Then you can use not only methods supported by `Model` but also almost all methods which can be used in `Eloquent` such as:

- [where](README.md#where)
- [whereIn](README.md#whereIn)
- [orderBy](README.md#orderby)
- [orderByDesc](README.md#orderbyDesc)
- [groupBy](README.md#groupBy)
- [groupByDesc](README.md#groupByDesc)
- [latest](README.md#latest)
- [take](README.md#take)
- [skip](README.md#skip)
- [distinct](README.md#distinct)
- [all](README.md#all)
- [get](README.md#get)
- [select](README.md#select)
- [search](README.md#search)
- [create](README.md#create)
- [update](README.md#update)
- [delete](README.md#delete)

Example:

```dart
 var user = User();

 var query = await user.cars();

 query.where('name','Honda').get();
 // Or
 query.search('hond');
 // Or
 query.orderByDesc().take(2).get();

 // etc ....
```

### One-To-One

- ### Example Scenario

  For example, **a user** may have **a car** and **a car** belongs to **a user**.

- ### Table Structure

  E.g,

  ```
  users
    id - integer
    name - string

  cars
    id - integer
    userId - integer
    name - string
  ```

- ### Create foreign fields

  You can create foreign keys by using `DB.foreign()`.

  For example, let's create `cars` table.

  ```dart
   await DB.createTable(db, tableName: 'cars', columns: {
        'id': [ColumnType.idType],
        'userId': DB.foreign(
            foreignKey: 'userId',
            parentKey: 'id',
            parentTable: 'users',
            type: ColumnType.integerType,
            onDelete: DBActions.cascade,
            onUpdate: null),
        'name': [ColumnType.stringType, ColumnType.notNull],
        'createdAt': [ColumnType.stringType, ColumnType.notNull],
        'updatedAt': [ColumnType.stringType, ColumnType.notNull],
      });
    };
  ```

- ### Add `OneToOne` mixin.

  ```dart
  import 'package:wazeloquent/wazeloquent.dart';

  class User extends RelationshipModel with OneToOne{}
  ```

- ### Determine which method to use in your model.

  Since user **has** car and a car **belongs to** a user,
  you can use `hasOne` in `User` class and `belongsTo` in `Car` class.

  For user,

  ```dart
  class User extends RelationshipModel with OneToOne{
    factory User.fromDB(Map<String, Object?> user) {
      return User(...);
    }

    Future<RelationshipModel> getCar() async {
      return await hasOne('cars');
    }

    static Future<User> withCar(Map<String, Object?> data) async {
      var user = User(
          id: int.parse(data['id'].toString()),
          name: data['name'].toString(),
          password: data['password'].toString(),
          createdAt: DateTime.parse(data['createdAt'].toString()),
          updatedAt: DateTime.parse(data['updatedAt'].toString()));
      var cars = await (await user.getCar()).get();
      if (cars != null && cars.isNotEmpty) {
        user.car = Car.fromDB(cars.first);
      }
      return user;
    }
  }

  //Then
  var data = UserEloquent().find(1);
  User userWithoutCar = User(data);
  User userWithCar = User.withCar(data);

  print(userWithoutCar.car); // null
  print(userWithCar.car); // car model
  ```

  For car,

  ```dart
  class Car extends RelationshipModel with OneToOne{
     factory Car.fromDB(Map<String, Object?> data) {
      return Car( ... );
    }

    static Future<Car> withUser(Map<String, Object?> data) async {
      var car = Car(
          id: int.parse(data['id'].toString()),
          userId: data['userId'].toString(),
          name: data['name'].toString());
      var users = await (await car.getUser()).get();
      if (users != null && users.isNotEmpty) {
        car.user = User.fromDB(users.first);
      }
      return car;
    }

    Future<RelationshipModel> getUser() async {
      return belongsTo('users');
    }
  }

  //Then
  var data = CarEloquent().find(1);
  Car carWithoutUser = Car(data);
  Car carWithUser = Car.withUser(data);

  print(carWithoutUser.user); // null
  print(carWithUser.user); // user model
  ```

- ### Getting results

  You can get the results by using `get`,`all`,`search`.

  ```dart
  var user = User();
  var carQuery = await user.car();
  await carQuery.get();
  ```

- ### Creating record
  You can create child record from parent.
  Foreign key will automatically inject in creating record.
  E.g
  ```dart
  var user = User();
  var carQuery = await user.car();
  await carQuery.create({
    'name':'Penske PC-23',
    'createdAt':DateTime.now(),
    'updatedAt':DateTime.now()
  });
  ```

> Note: You cannot create parent data from child.

- ### Updating record

  Use `update` method to update model's attributes in database.

  ```dart
  var user = User();
  var carQuery = await user.car();
  await carQuery.update({
      'name':'New car'
  });
  ```

- ### Deleting Model

  Use `delete` method to delete model's attributes in database.

  ```dart
  var user = User();
  var carQuery = await user.car();
  await carQuery.delete();
  ```

> You can check example [here](example/lib/pages/one_to_one.dart)

### One-To-Many

- ### Example Scenario

  For example, **a user** may have **one or more cars** and **a car** belongs to **a user**.

- ### Table Structure

  E.g,

  ```
  users
    id - integer
    name - string

  cars
    id - integer
    userId - integer
    name - string
  ```

- ### Create foreign keys and extend `RelationshipModel`

  See [above](#create-foreign-fields).

- ### Add `OneToMany` mixin.

  ```dart
  class User extends RelationshipModel with OneToMany{}
  ```

- ### Determine which method to use in your model.

  Since user has one or more cars and a car belongs to a user,
  you can use `hasMany` in `User` class and `belongsTo` in `Car` class.

  For user,

  ```dart
  class User extends Model with OneToMany{
    factory User.fromDB(Map<String, Object?> user) {
      return User(...);
    }

    Future<RelationshipModel> getCars() async {
      return hasMany('cars');
    }

    static Future<User> withCars(Map<String, Object?> data) async {
      var user = User(
          id: int.parse(data['id'].toString()),
          name: data['name'].toString(),
          password: data['password'].toString(),
          createdAt: DateTime.parse(data['createdAt'].toString()),
          updatedAt: DateTime.parse(data['updatedAt'].toString()));
      var cars = await (await user.getCars()).get();
      if (cars != null && cars.isNotEmpty) {
        for (var car in cars) {
          user.cars.add(Car.fromDB(car));
        }
      }
      return user;
    }
  }

  //Then
  var data = UserEloquent().find(1);
  User userWithoutCars = User(data);
  User userWithCars = User.withCar(data);

  print(userWithoutCar.cars); // []
  print(userWithCar.cars); // List<Car>
  ```

  For car,

  ```dart
  class Car extends RelationshipModel with OneToMany{
     factory Car.fromDB(Map<String, Object?> data) {
      return Car( ... );
    }

    static Future<Car> withUser(Map<String, Object?> data) async {
      var car = Car(
          id: int.parse(data['id'].toString()),
          userId: data['userId'].toString(),
          name: data['name'].toString());
      var users = await (await car.getUser()).get();
      if (users != null && users.isNotEmpty) {
        car.user = User.fromDB(users.first);
      }
      return car;
    }

    Future<RelationshipModel> getUser() async {
      return belongsTo('users');
    }
  }

  //Then
  var data = CarEloquent().find(1);
  Car carWithoutUser = Car(data);
  Car carWithUser = Car.withUser(data);

  print(carWithoutUser.user); // null
  print(carWithUser.user); // user model
  ```

- ### Getting results

  You can get the results by using `get`,`all`,`search`.

  ```dart
  var user = User();
  var carQuery = await user.cars();
  await carQuery.get();
  ```

- ### Creating record or records

  You can create child record or records from parent.
  Foreign key will automatically inject in creating record.
  E.g

  ```dart
  var user = User();
  var carQuery = await user.cars();
  await carQuery.create({
    'name':'Penske PC-23',
    'createdAt':DateTime.now(),
    'updatedAt':DateTime.now()
  });

  await carQuery.createMany([
    {
     'name':'Penske PC-23',
     'createdAt':DateTime.now(),
     'updatedAt':DateTime.now()
    },{
     'name':'Buick Regal.',
     'createdAt':DateTime.now(),
     'updatedAt':DateTime.now()
    }
  ]);
  ```

> Note: You cannot create parent data from child.

- ### Updating a record or records

  Use `update` method to update model's attributes in database.

  ```dart
  var user = User();
  var carQuery = await user.cars();
  await carQuery.update({
      'name':'New car'
  });
  ```

- ### Deleting a record or records
  Use `delete` method to delete model's attributes in database.
  ```dart
  var user = User();
  var carQuery = await user.cars();
  await carQuery.delete();
  ```

> You can check example [here](example/lib/pages/one_to_many.dart)

## Many-To-Many

You need a pivot table for this relationship.

> Pivot table name should be in alphabetical order.
> For example, `class_student` or `role_user`.
> If not in alphabetical order, you must specify pivot table.

### Example Scenario

A student can belong to one or more classes and a class can belong to one or more students.

Table example structures are

```
students
  id - integer
  name - string

classes
  id - integer
  name - string

class_student
  id - integer
  studentId - integer
  classId - integer

```

- ### Create foreign keys and extend `RelationshipModel`

  See [above](#create-foreign-fields).

- ### Add `ManyToMany` mixin.

  ```dart
  class User extends RelationshipModel with ManyToMany{}
  ```

- ### Determine which method to use in your model.
  For `ManyToMany` relationship, you only need to use one method `belongsToMany`.

```dart
class Student extends RelationshipModel with ManyToMany {

  factory Student.fromDB(Map<String, Object?> user) {
    return Student(...);
  }

   Future<ManyToMany> getClasses() {
    return belongsToMany('classes');
  }

  static Future<Student> withClasses(Map<String, Object?> data) async {
    // print(json.decode(data['createdAt']));
    var student = Student(
        id: int.parse(data['id'].toString()),
        name: data['name'].toString(),
        createdAt: DateTime.parse(data['createdAt'].toString()),
        updatedAt: DateTime.parse(data['updatedAt'].toString()));
    var results = await (await student.getClasses()).get();
    if (results != null) {
      for (var classroom in results) {
        student.classes.add(Class.fromDB(classroom));
      }
    }
    return student;
  }
}

class Class extends RelationshipModel with OneToOne, OneToMany, ManyToMany {
  factory Class.fromDB(Map<String, Object?> data) {
    return Class(...);
  }

  Future<ManyToMany> getStudents() {
    return belongsToMany('students');
  }

  static Future<Class> withStudents(Map<String, Object?> data) async {
    // print(json.decode(data['createdAt']));
    var classroom = Class(
        id: int.parse(data['id'].toString()),
        name: data['name'].toString(),
        createdAt: DateTime.parse(data['createdAt'].toString()),
        updatedAt: DateTime.parse(data['updatedAt'].toString()));
    var results = await (await classroom.getStudents()).get();
    if (results != null) {
      for (var student in results) {
        classroom.students.add(Student.fromDB(student));
      }
    }
    return classroom;
  }
}

```

- ### Getting results

  You can get the results by using `get`,`all`,`search`.

  ```dart
  var classroom = Class();
  var query = await classroom.getStudents();
  await query.get();
  ```

- ### Attaching record

  To create record in pivot table, use
  `attach` or `attachMany` method.

  E.g

  ```dart
  var classroom = Class();
  var student = Student();
  var query = await classroom.getStudents();
  await query.attach(student);

  await query.attachMany([Student(),Student()]);
  ```

  You can specify extra column values to add in pivot table.

  ```dart
  await query.attach(student,extras:{
    'extraColumn':'value',
  })
  ```

- ### Updating a record or records

  Use `update` method to update model's attributes in database.

  ```dart
  var student = Student();
  var classQuery = await student.getClasses();
  await classQuery.update({
      'name':'New class'
  });
  ```

- ### Detaching record

  To delete related row or rows in pivot table, you can use `detach` method. In order to delete a single record, specify your model as `model` parameter.

  ```dart
  var student = Student();
  var classQuery = await student.getClasses();

  // Delete single row in pivot table
  await classQuery.detach(model:Class());

  // delete all related rows in pivot table
  await classQuery.detach();
  ```

> You can check example [here](example/lib/pages/many_to_many.dart)

You can use multiple relationships in the same model. Eg,

```dart
class User extends RelationshipModel with OneToOne,OneToMany,ManyToMany{}
```
