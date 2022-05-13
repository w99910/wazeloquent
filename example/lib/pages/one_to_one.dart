import 'dart:developer';
import 'dart:math';

import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/user.dart';
import 'package:example/models/car.dart';
import 'package:example/models/user.dart';
import 'package:flutter/material.dart';

class OneToOne extends StatefulWidget {
  const OneToOne({Key? key}) : super(key: key);

  @override
  State<OneToOne> createState() => _OneToOneState();
}

const carNames = ['Lamborghini Diablo', 'Ford Raptor', 'Ferrari Testarossa'];

class _OneToOneState extends State<OneToOne> {
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
    inspect(cars);

    setState(() {
      cars = cars;
    });
  }

  create() async {
    var data = await carEloquent.create(values: {
      'name': carNames[Random().nextInt(carNames.length)],
      'user_id': users[Random().nextInt(users.length)].id,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String()
    });

    // var data = await userEloquent.createIfNotExists(check: {
    //   'id': 1
    // }, create: {
    //   'name': names[Random().nextInt(4)],
    //   'password': 'pass',
    //   'createdAt': DateTime.now().toIso8601String(),
    //   'updatedAt': DateTime.now().toIso8601String()
    // });
    showSnack('Created id - $data');
    loadCars();
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
              children: [
                ElevatedButton(
                    onPressed: create, child: const Text('Create Car')),
                ElevatedButton(
                    onPressed: delete, child: const Text('Delete Car')),
                ElevatedButton(
                    onPressed: () {}, child: const Text('Update Car')),
                ElevatedButton(
                    onPressed: () {},
                    child: const Text('Filter Cars by user name')),
                ElevatedButton(
                    onPressed: () {}, child: const Text('Order desc')),
                ElevatedButton(
                    onPressed: loadUsers, child: const Text('Reload')),
                ElevatedButton(onPressed: () {}, child: const Text('Skip')),
                ElevatedButton(onPressed: () {}, child: const Text('Take 2'))
              ],
            ),
          )
        ]),
      ),
    );
  }
}