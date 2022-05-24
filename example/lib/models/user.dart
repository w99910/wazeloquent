import 'package:example/eloquents/user.dart';
import 'package:example/models/car.dart';
import 'package:wazeloquent/wazeloquent.dart';

class User extends RelationshipModel with OneToOne, OneToMany, ManyToMany {
  int id;
  String name;
  String password;
  DateTime? createdAt;
  DateTime? updatedAt;
  Car? car;
  List<Car> cars = [];
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

  Future<RelationshipModel> getCar() async {
    return hasOne('cars');
  }

  Future<RelationshipModel> getCars() async {
    return hasMany('cars');
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
  @override
  setPrimaryValue(value) {
    id = value;
  }
}
