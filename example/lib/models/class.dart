import 'package:example/eloquents/class.dart';
import 'package:example/models/student.dart';
import 'package:wazeloquent/wazeloquent.dart';

class Class extends RelationshipModel with OneToOne, OneToMany, ManyToMany {
  int id;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  final List<Student> students = [];
  Class({required this.id, required this.name, this.createdAt, this.updatedAt});

  factory Class.fromDB(Map<String, Object?> data) {
    return Class(
        id: int.parse(data['id'].toString()),
        name: data['name'].toString(),
        createdAt: DateTime.parse(data['createdAt'].toString()),
        updatedAt: DateTime.parse(data['updatedAt'].toString()));
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

  @override
  Eloquent get eloquent => ClassEloquent();

  @override
  String get primaryValue => id.toString();

  @override
  Map<String, Object?> get toJson => {
        'name': name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String()
      };

  @override
  setPrimaryValue(value) {
    id = value;
  }
}
