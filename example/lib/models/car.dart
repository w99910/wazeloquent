import 'package:example/eloquents/car.dart';
import 'package:example/models/user.dart';
import 'package:wazeloquent/wazeloquent.dart';

class Car extends RelationshipModel with OneToOne {
  int id;
  String name;
  String userId;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? user;
  Car(
      {required this.id,
      required this.name,
      required this.userId,
      this.createdAt,
      this.updatedAt});

  factory Car.fromDB(Map<String, Object?> data) {
    return Car(
        id: int.parse(data['id'].toString()),
        userId: data['user_id'].toString(),
        name: data['name'].toString());
  }

  static Future<Car> withUser(Map<String, Object?> data) async {
    var car = Car(
        id: int.parse(data['id'].toString()),
        userId: data['user_id'].toString(),
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

  @override
  Eloquent get eloquent => CarEloquent();

  @override
  String get primaryValue => id.toString();

  @override
  Map<String, Object?> get toJson => {
        'name': name,
        'user_id': userId,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String()
      };
}
