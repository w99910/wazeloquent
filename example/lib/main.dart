import 'dart:developer';
import 'dart:math';

import 'package:example/eloquents/user.dart';
import 'package:example/models/user.dart';
import 'package:flutter/material.dart';
import 'package:wazeloquent/wazeloquent.dart';

void main() async {
  var db = DB.instance;
  db.setDbVersion(1); // set db version
  db.setFileName('example.db'); // set file
  db.onCreate([UserEloquent.onCreate]);
  db.onOpen([UserEloquent.onOpen]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WazEloquent Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final List<String> names = ['John', 'Doe', 'Sam', 'Dean', 'Jenny'];

class _MyHomePageState extends State<MyHomePage> {
  final UserEloquent userEloquent = UserEloquent();
  List<User> users = [];
  @override
  void initState() {
    loadUsers();
    super.initState();
  }

  showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  createUser() async {
    var data = await userEloquent.create(values: {
      'name': names[Random().nextInt(4)],
      'password': 'pass',
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
    loadUsers();
  }

  orderUser() async {
    var data = await userEloquent.orderByDesc('name').get();
    updateState(data);
  }

  deleteUser() async {
    if (users.isNotEmpty) {
      User user = users.first;
      var response =
          await userEloquent.where('id', user.id.toString()).delete();
      showSnack('Total deleted - ' + response.toString());
      loadUsers();
    }

    // var data = await userEloquent.createIfNotExists(check: {
    //   'id': 1
    // }, create: {
    //   'name': names[Random().nextInt(4)],
    //   'password': 'pass',
    //   'createdAt': DateTime.now().toIso8601String(),
    //   'updatedAt': DateTime.now().toIso8601String()
    // });
  }

  updateUser() async {
    if (users.isNotEmpty) {
      User user = users.first;
      var response = await userEloquent
          .where('id', user.id.toString())
          .update({'name': 'Micheal'});
      showSnack('Total updated - ' + response.toString());
      loadUsers();
    }
  }

  filterUser() async {
    var data = await userEloquent.where('name', 'Dean').get();
    if (data == null || data.isEmpty) {
      showSnack('No user found');
      return;
    }
    showSnack('Dean User Filter');
    updateState(data);
  }

  loadUsers() async {
    var data = await userEloquent.all();
    updateState(data);
  }

  skipUsers() async {
    var data = await userEloquent.skip(1).get();
    updateState(data);
  }

  take() async {
    var data = await userEloquent.take(2).get();
    updateState(data);
  }

  updateState(List<Map<String, Object?>>? data) {
    if (data == null) {
      showSnack('Empty');
    }
    users = [];
    for (var user in data!) {
      users.add(User(
          id: int.parse(user['id'].toString()),
          name: user['name'].toString(),
          password: user['password'].toString(),
          createdAt: DateTime.parse(user['createdAt'].toString()),
          updatedAt: DateTime.parse(user['updatedAt'].toString())));
    }

    setState(() {
      users = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SizedBox(
        width: size.width * 0.95,
        height: size.height,
        child: Column(children: [
          const SizedBox(height: 20),
          SizedBox(
              height: size.height * 0.45,
              width: size.width * 0.7,
              child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, int index) {
                    User user = users[index];
                    return ListTile(
                      leading: Text(user.id.toString()),
                      title: Text(user.name),
                    );
                  })),
          SizedBox(
            height: size.height * 0.4,
            width: size.width * 0.7,
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                    onPressed: createUser, child: const Text('Create User')),
                ElevatedButton(
                    onPressed: deleteUser, child: const Text('Delete User')),
                ElevatedButton(
                    onPressed: updateUser, child: const Text('Update User')),
                ElevatedButton(
                    onPressed: filterUser, child: const Text('Filter User')),
                ElevatedButton(
                    onPressed: orderUser, child: const Text('Order desc')),
                ElevatedButton(
                    onPressed: loadUsers, child: const Text('Reload')),
                ElevatedButton(onPressed: skipUsers, child: const Text('Skip')),
                ElevatedButton(
                    onPressed: skipUsers, child: const Text('Take 2'))
              ],
            ),
          )
        ]),
      ),
    );
  }
}
