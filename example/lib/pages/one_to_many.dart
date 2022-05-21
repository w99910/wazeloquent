import 'dart:developer';
import 'dart:math';

import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/user.dart';
import 'package:example/models/car.dart';
import 'package:example/models/user.dart';
import 'package:flutter/material.dart';

class OneToManyWidget extends StatefulWidget {
  const OneToManyWidget({Key? key}) : super(key: key);

  @override
  State<OneToManyWidget> createState() => _OneToManyWidgetState();
}

const carNames = [
  'Lamborghini Diablo',
  'Ford Raptor',
  'Ferrari Testarossa',
  'Porsche 911 Carrera',
  'Jeep Gladiator'
];

class _OneToManyWidgetState extends State<OneToManyWidget> {
  final CarEloquent carEloquent = CarEloquent();
  final UserEloquent userEloquent = UserEloquent();
  List<User> users = [];
  List<Car> cars = [];
  @override
  void initState() {
    loadUsers();
    loadCars();
    super.initState();
  }

  showSnack(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(milliseconds: 600),
    ));
  }

  loadCars() async {
    var data = await carEloquent.all();
    updateCarState(data);
  }

  loadUsers() async {
    var data = await userEloquent.all();
    updateUserState(data);
  }

  updateUserState(List<Map<String, Object?>>? data) async {
    if (data == null) {
      showSnack('Empty');
    }
    users = [];
    for (var user in data!) {
      users.add(await User.withCars(user));
    }

    setState(() {
      users = users;
    });
  }

  updateCarState(List<Map<String, Object?>>? data) async {
    if (data == null) {
      showSnack('Empty');
    }
    cars = [];
    for (var car in data!) {
      cars.add(await Car.withUser(car));
    }

    setState(() {
      cars = cars;
    });
  }

  create() async {
    if (users.isEmpty) {
      showSnack('Empty User');
      return;
    }
    var data = await carEloquent.create({
      'name': carNames[Random().nextInt(carNames.length)],
      'user_id': users[Random().nextInt(users.length)].id,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String()
    });
    showSnack('Created id - $data');
    loadUsers();
  }

  filterCars() async {
    User user = users[Random().nextInt(users.length)];
    showSnack(
      'Filtering for cars which ${user.name} owns ... ',
    );
  }

  delete() async {
    if (cars.isEmpty) {
      showSnack('Empty car');
      return;
    }
    var data = await carEloquent.where('id', cars.first.id.toString()).delete();
    showSnack('Delete rows - $data');
    loadCars();
  }

  search() async {
    if (users.isEmpty) {
      showSnack('Empty user');
    }
    User user = users[Random().nextInt(users.length)];
    showSnack('Searching for "F" cars which ${user.name} owns ... ',
        duration: const Duration(milliseconds: 1500));
    var data = await (await user.getCars()).search('F');
    List<String> searchCarIds = data.map((e) => e['id'].toString()).toList();
    showSnack('Search rows - ${data.length}');
    List<User> temp = [];
    for (var user in users) {
      if (user.cars.isNotEmpty &&
          user.cars
              .where((element) => searchCarIds.contains(element.id.toString()))
              .isNotEmpty) {
        temp.add(user);
      }
    }
    setState(() {
      users = temp;
    });
  }

  orderDesc() async {
    User user = users[Random().nextInt(users.length)];
    showSnack('Ordering desc for ${user.name}',
        duration: const Duration(milliseconds: 2000));
    var data = await (await user.getCars()).orderByDesc('name').get();
    int index = users.indexOf(user);
    List<Car> temp = [];
    user.cars = [];
    if (data != null) {
      for (var car in data) {
        temp.add(Car.fromDB(car));
      }
    }
    user.cars = temp;
    setState(() {
      users[index] = user;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: SizedBox(
        width: size.width * 0.95,
        height: size.height,
        child: Column(children: [
          const SizedBox(height: 20),
          SizedBox(
              height: size.height * 0.6,
              width: size.width * 0.7,
              child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, int index) {
                    User user = users[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style:
                              const TextStyle(color: Colors.blue, fontSize: 20),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: user.cars.length * 60,
                          child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: user.cars.length,
                              itemBuilder: (context, index) {
                                Car car = user.cars[index];
                                return ListTile(
                                  title: Text('-  ' + car.name),
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
                    onPressed: create, child: const Text('Create Car')),
                ElevatedButton(
                    onPressed: delete, child: const Text('Delete Car')),
                ElevatedButton(
                    onPressed: () {}, child: const Text('Update Car')),
                ElevatedButton(
                    onPressed: filterCars, child: const Text('Filter Car')),
                ElevatedButton(
                    onPressed: search,
                    child: const Text('Search cars via user')),
                ElevatedButton(
                    onPressed: orderDesc, child: const Text('Order desc')),
                ElevatedButton(
                    onPressed: loadUsers, child: const Text('Reload')),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
