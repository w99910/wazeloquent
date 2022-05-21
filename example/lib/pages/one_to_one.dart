import 'dart:developer';
import 'dart:math';

import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/user.dart';
import 'package:example/models/car.dart';
import 'package:example/models/user.dart';
import 'package:flutter/material.dart';

class OneToOneWidget extends StatefulWidget {
  const OneToOneWidget({Key? key}) : super(key: key);

  @override
  State<OneToOneWidget> createState() => _OneToOneWidgetState();
}

const carNames = [
  'Lamborghini Diablo',
  'Ford Raptor',
  'Ferrari Testarossa',
  'Porsche 911 Carrera',
  'Jeep Gladiator'
];

class _OneToOneWidgetState extends State<OneToOneWidget> {
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

  showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 600),
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
      users.add(await User.withCar(user));
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

  update() async {
    if (cars.isEmpty) {
      showSnack('Empty car');
      return;
    }
    User user = users[Random().nextInt(users.length)];
    var data = await (await user.getCar()).update({'name': 'Audi R8'});

    showSnack('Updated - $data');
    loadCars();
  }

  create() async {
    if (users.isEmpty) {
      showSnack('Empty User');
      return;
    }
    var data =
        await (await users[Random().nextInt(users.length)].getCar()).create({
      'name': carNames[Random().nextInt(carNames.length)],
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String()
    });
    showSnack('Created id - $data');
    loadCars();
  }

  delete() async {
    if (cars.isEmpty) {
      showSnack('Empty car');
      return;
    }
    User user = users[Random().nextInt(users.length)];
    var data = await (await user.getCar()).delete();
    showSnack('Delete rows - $data where user name : ${user.name}');
    loadCars();
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
              height: size.height * 0.45,
              width: size.width * 0.7,
              child: ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (_, int index) {
                    Car car = cars[index];
                    return ListTile(
                      leading: Text(car.id.toString()),
                      title: Text(car.name),
                      subtitle: Text(car.user!.name),
                    );
                  })),
          SizedBox(
            height: size.height * 0.4,
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
                    onPressed: update, child: const Text('Update Car')),
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
