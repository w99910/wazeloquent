import 'dart:math';

import 'package:example/eloquents/class.dart';
import 'package:example/eloquents/student.dart';
import 'package:example/models/class.dart';
import 'package:example/models/student.dart';
import 'package:flutter/material.dart';

class ManyToManyWidget extends StatefulWidget {
  const ManyToManyWidget({Key? key}) : super(key: key);

  @override
  State<ManyToManyWidget> createState() => _ManyToManyWidgetState();
}

const studentNames = [
  'Student A',
  'Student B',
  'Student C',
  'Student D',
  'Student E'
];

const classroomNames = [
  'Class A',
  'Class B',
  'Class C',
  'Class D',
  'Class E',
];

class _ManyToManyWidgetState extends State<ManyToManyWidget> {
  final studentEloquent = StudentEloquent();
  final classEloquent = ClassEloquent();
  final List<Student> students = [];
  final List<Class> classes = [];
  int selectedStudentIndex = -1;
  int selectedClassIndex = -1;
  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    await loadClasses();
    await loadStudents();
    // var country = Country(id: 1, name: 'UK');
    // await country.save();
    // var query = await country.users();
    // var users = await userEloquent.get();
    // if (users != null && users.isNotEmpty) {
    //   var user = User.fromDB(users[1]);
    // await query.attach(user, extras: {
    //   'createdAt': "'${DateTime.now().toIso8601String()}'",
    //   'updatedAt': "'${DateTime.now().toIso8601String()}'",
    // });
    //   await query.detach(model: User.fromDB(users[1]));
    // }

    // print(await (await country.users()).get());
  }

  showSnack(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(milliseconds: 600),
    ));
  }

  createStudent() async {
    String name = studentNames[Random().nextInt(studentNames.length)];
    await studentEloquent.updateOrCreate(check: {
      'name': name,
    }, inserts: {
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await loadStudents();
  }

  createClass() async {
    String name = classroomNames[Random().nextInt(classroomNames.length)];
    await classEloquent.updateOrCreate(check: {
      'name': name,
    }, inserts: {
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await loadClasses();
  }

  attach(Class classroom, Student student) async {
    var query = await classroom.getStudents();
    var result = await query.attach(student, extras: {
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    showSnack('Attach result: $result');
    loadClasses();
  }

  detach(Class classroom, Student student) async {
    var query = await classroom.getStudents();
    var result = await query.detach(model: student);
    showSnack('detach result: $result');
    loadClasses();
  }

  detachAll(Class classroom) async {
    var query = await classroom.getStudents();
    var result = await query.detach();
    showSnack('detach result: $result');
    loadClasses();
  }

  // create() async {
  //   if (users.isEmpty) {
  //     showSnack('Empty User');
  //     return;
  //   }
  //   // var data = await carEloquent.create({
  //   //   'name': countryNames[Random().nextInt(countryNames.length)],
  //   //   'user_id': users[Random().nextInt(users.length)].id,
  //   //   'createdAt': DateTime.now().toIso8601String(),
  //   //   'updatedAt': DateTime.now().toIso8601String()
  //   // });
  //   // showSnack('Created id - $data');
  //   loadUsers();
  // }

  loadStudents() async {
    var data = await studentEloquent.all();
    updateStudentsState(data);
  }

  updateStudentsState(List<Map<String, Object?>>? data) async {
    if (data == null) {
      showSnack('Empty');
    }
    students.clear();
    var temp = <Student>[];
    for (var row in data!) {
      temp.add(Student.fromDB(row));
    }

    setState(() {
      students.addAll(temp);
    });
  }

  loadClasses() async {
    var data = await classEloquent.all();
    updateClassState(data);
  }

  updateClassState(List<Map<String, Object?>>? data) async {
    if (data == null) {
      showSnack('Empty');
    }
    classes.clear();
    var temp = <Class>[];
    for (var row in data!) {
      temp.add(await Class.withStudents(row));
    }

    setState(() {
      classes.addAll(temp);
    });
  }

  // filterCars() async {
  //   User user = users[Random().nextInt(users.length)];
  //   showSnack(
  //     'Filtering for cars which ${user.name} owns ... ',
  //   );
  // }

  // delete() async {
  //   if (users.isEmpty) {
  //     showSnack('Empty car');
  //     return;
  //   }
  //   // var data = await carEloquent.where('id', cars.first.id.toString()).delete();
  //   // showSnack('Delete rows - $data');
  //   // loadCars();
  // }

  // search() async {
  //   if (users.isEmpty) {
  //     showSnack('Empty user');
  //   }
  //   users.clear();
  //   User user = users[Random().nextInt(users.length)];
  //   showSnack('Searching for "F" cars which ${user.name} owns ... ',
  //       duration: const Duration(milliseconds: 1500));
  //   var data = await (await user.getCars()).search('F');
  //   List<String> searchCarIds = data.map((e) => e['id'].toString()).toList();
  //   showSnack('Search rows - ${data.length}');
  //   List<User> temp = [];
  //   for (var user in users) {
  //     if (user.cars.isNotEmpty &&
  //         user.cars
  //             .where((element) => searchCarIds.contains(element.id.toString()))
  //             .isNotEmpty) {
  //       temp.add(user);
  //     }
  //   }
  //   setState(() {
  //     users.addAll(temp);
  //   });
  // }

  // orderDesc() async {
  //   User user = users[Random().nextInt(users.length)];
  //   showSnack('Ordering desc for ${user.name}',
  //       duration: const Duration(milliseconds: 2000));
  //   var data = await (await user.getCars()).orderByDesc('name').get();
  //   int index = users.indexOf(user);
  //   // List<Car> temp = [];
  //   // user.cars = [];
  //   // if (data != null) {
  //   //   for (var car in data) {
  //   //     temp.add(Car.fromDB(car));
  //   //   }
  //   // }
  //   // user.cars = temp;
  //   setState(() {
  //     users[index] = user;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: SizedBox(
        width: size.width * 0.95,
        height: size.height,
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Column(children: [
            const SizedBox(height: 10),
            const Text('Classes'),
            const SizedBox(height: 10),
            SizedBox(
              height: classes.length * 80,
              width: size.width * 0.7,
              child: buildClassLists(),
            ),
            const Text('Students'),
            const SizedBox(height: 10),
            SizedBox(
              height: students.length * 80,
              width: size.width * 0.7,
              child: buildStudentLists(),
            ),
            const SizedBox(height: 10),
            SizedBox(
                height: size.height * 0.6,
                width: size.width * 0.7,
                child: ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (_, int index) {
                      Class classroom = classes[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classroom.name,
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 20),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: classroom.students.length * 60,
                            child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: classroom.students.length,
                                itemBuilder: (context, index) {
                                  Student student = classroom.students[index];
                                  return ListTile(
                                    title: Text('-  ' + student.name),
                                  );
                                }),
                          )
                        ],
                      );
                    })),
            SizedBox(
              height: size.height * 0.2,
              width: size.width * 0.7,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                      onPressed: createStudent,
                      child: const Text('Create Student')),
                  ElevatedButton(
                      onPressed: createClass,
                      child: const Text('Create Class')),
                  ElevatedButton(
                      onPressed:
                          selectedClassIndex != -1 && selectedStudentIndex != -1
                              ? () => attach(classes[selectedClassIndex],
                                  students[selectedStudentIndex])
                              : null,
                      child: const Text('Attach Student to class')),
                  ElevatedButton(
                      onPressed:
                          selectedClassIndex != -1 && selectedStudentIndex != -1
                              ? () => detach(classes[selectedClassIndex],
                                  students[selectedStudentIndex])
                              : null,
                      child: const Text('Detach Student from class')),
                  ElevatedButton(
                      onPressed: selectedClassIndex != -1
                          ? () => detachAll(classes[selectedClassIndex])
                          : null,
                      child: const Text('Detach all from selected class')),
                  // ElevatedButton(
                  //     onPressed: orderDesc, child: const Text('Order desc')),
                  ElevatedButton(onPressed: init, child: const Text('Reload')),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget buildStudentLists() {
    return ListView.separated(
        controller: ScrollController(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Checkbox(
              value: selectedStudentIndex == index,
              onChanged: (value) {
                if (value != null) {
                  if (value) {
                    setState(() {
                      selectedStudentIndex = index;
                    });
                  } else {
                    setState(() {
                      selectedStudentIndex = -1;
                    });
                  }
                }
              },
            ),
            title: Text(students[index].name),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: students.length);
  }

  Widget buildClassLists() {
    return ListView.separated(
        controller: ScrollController(),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Checkbox(
              value: selectedClassIndex == index,
              onChanged: (value) {
                if (value != null) {
                  if (value) {
                    setState(() {
                      selectedClassIndex = index;
                    });
                  } else {
                    setState(() {
                      selectedClassIndex = -1;
                    });
                  }
                }
              },
            ),
            title: Text(classes[index].name),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: classes.length);
  }
}
