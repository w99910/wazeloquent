import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/country.dart';
import 'package:example/models/user.dart';
import 'package:wazeloquent/wazeloquent.dart';

class Country extends RelationshipModel with OneToOne, ManyToMany {
  int id;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  User? user;
  Country(
      {required this.id, required this.name, this.createdAt, this.updatedAt});

  factory Country.fromDB(Map<String, Object?> data) {
    return Country(
      id: int.parse(data['id'].toString()),
      name: data['name'].toString(),
      createdAt: DateTime.parse(data['createdAt'].toString()),
      updatedAt: DateTime.parse(data['updatedAt'].toString()),
    );
  }

  users() async {
    return belongsToMany('users');
  }

  // static Future<Car> withUser(Map<String, Object?> data) async {
  //   var car = Car(
  //       id: int.parse(data['id'].toString()),
  //       userId: data['user_id'].toString(),
  //       name: data['name'].toString());
  //   var users = await (await car.getUser()).get();
  //   if (users != null && users.isNotEmpty) {
  //     car.user = User.fromDB(users.first);
  //   }
  //   return car;
  // }

  Future<RelationshipModel> getUser() async {
    return belongsTo('users');
  }

  @override
  Eloquent get eloquent => CountryEloquent();

  @override
  String get primaryValue => id.toString();

  @override
  Map<String, Object?> get toJson => {
        'name': name,
        'createdAt': createdAt != null
            ? createdAt?.toIso8601String()
            : DateTime.now().toIso8601String(),
        'updatedAt': updatedAt != null
            ? updatedAt?.toIso8601String()
            : DateTime.now().toIso8601String(),
      };
}
