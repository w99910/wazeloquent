import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/user.dart';
import 'package:example/models/car.dart';

class User {
  int id;
  String name;
  String password;
  DateTime? createdAt;
  DateTime? updatedAt;
  Car? car;
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
    var userEloquent = UserEloquent();
    var car = await userEloquent.where('id', id.toString()).hasOne('cars');
    if (car != null) {
      return Car.fromDB(car);
    }
    return null;
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
}
