import 'package:example/eloquents/student.dart';
import 'package:wazeloquent/wazeloquent.dart';

class Student extends RelationshipModel with OneToOne, OneToMany, ManyToMany {
  int id;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  Student(
      {required this.id, required this.name, this.createdAt, this.updatedAt});

  factory Student.fromDB(Map<String, Object?> user) {
    return Student(
        id: int.parse(user['id'].toString()),
        name: user['name'].toString(),
        createdAt: DateTime.parse(user['createdAt'].toString()),
        updatedAt: DateTime.parse(user['updatedAt'].toString()));
  }

  Future<ManyToMany> classes() {
    return belongsToMany('classes');
  }

  @override
  Eloquent get eloquent => StudentEloquent();

  @override
  String get primaryValue => id.toString();

  @override
  Map<String, Object?> get toJson => {
        'name': name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String()
      };
}
