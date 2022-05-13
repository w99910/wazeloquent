import 'dart:developer';

import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/user.dart';
import 'package:example/models/car.dart';
import 'package:wazeloquent/wazeloquent.dart';

class User extends Model with OneToOne, OneToMany {
  int id;
  String name;
  String password;
  DateTime? createdAt;
  DateTime? updatedAt;
  Car? car;
  final List<Car> cars = [];
  User(
      {required this.id,
      required this.name,
      required this.password,
      this.createdAt,
      this.updatedAt});

  factory User.fromDB(Map<String, Object?> user) {
    return User(
        id: int.parse(user['id'].toString()),
        name: user['name'].toString(),
        password: user['password'].toString(),
        createdAt: DateTime.parse(user['createdAt'].toString()),
        updatedAt: DateTime.parse(user['updatedAt'].toString()));
  }

  Future<Car?> getCar() async {
    var car = await hasOne('cars');
    if (car != null) {
      return Car.fromDB(car);
    }
    return null;
  }

  Future<List<Car>> getCars() async {
    var data = await hasMany('cars');
    List<Car> cars = [];
    for (var car in data) {
      cars.add(Car.fromDB(car));
    }
    return cars;
  }

  static Future<User> withCar(Map<String, Object?> data) async {
    var user = User(
        id: int.parse(data['id'].toString()),
        name: data['name'].toString(),
        password: data['password'].toString(),
        createdAt: DateTime.parse(data['createdAt'].toString()),
        updatedAt: DateTime.parse(data['updatedAt'].toString()));
    user.car = await user.getCar();
    return user;
  }

  static Future<User> withCars(Map<String, Object?> data) async {
    var user = User(
        id: int.parse(data['id'].toString()),
        name: data['name'].toString(),
        password: data['password'].toString(),
        createdAt: DateTime.parse(data['createdAt'].toString()),
        updatedAt: DateTime.parse(data['updatedAt'].toString()));
    user.cars.addAll(await user.getCars());
    return user;
  }

  @override
  Eloquent get eloquent => UserEloquent();

  @override
  String get primaryValue => id.toString();

  @override
  Map<String, Object?> get toJson => {
        'name': name,
        'password': password,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String()
      };
}
