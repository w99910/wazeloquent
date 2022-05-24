import 'package:example/eloquents/student.dart';
import 'package:example/models/class.dart';
import 'package:wazeloquent/wazeloquent.dart';

class Student extends RelationshipModel with OneToOne, OneToMany, ManyToMany {
  int id;
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
  final List<Class> classes = [];
  Student(
      {required this.id, required this.name, this.createdAt, this.updatedAt});

  factory Student.fromDB(Map<String, Object?> user) {
    return Student(
        id: int.parse(user['id'].toString()),
        name: user['name'].toString(),
        createdAt: DateTime.parse(user['createdAt'].toString()),
        updatedAt: DateTime.parse(user['updatedAt'].toString()));
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
