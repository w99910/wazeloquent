import 'package:example/eloquents/car.dart';
import 'package:example/models/user.dart';

class Car {
  int id;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? user;
  Car({required this.id, required this.name, this.createdAt, this.updatedAt});

  factory Car.fromDB(Map<String, Object?> data) {
    return Car(
        id: int.parse(data['id'].toString()), name: data['name'].toString());
  }

  static Future<Car> withUser(Map<String, Object?> data) async {
    var car = Car(
        id: int.parse(data['id'].toString()), name: data['name'].toString());
    car.user = await car.getUser();
    return car;
  }

  Future<User> getUser() async {
    var user =
        await CarEloquent().where('id', id.toString()).belongsTo('users');
    return User.fromDB(user!);
  }
}
