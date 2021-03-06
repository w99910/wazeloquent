import 'package:example/eloquents/car.dart';
import 'package:example/eloquents/class.dart';
import 'package:example/eloquents/student.dart';
import 'package:example/eloquents/user.dart';
import 'package:example/models/user.dart';
import 'package:example/pages/basic.dart';
import 'package:example/pages/many_to_many.dart';
import 'package:example/pages/one_to_many.dart';
import 'package:example/pages/one_to_one.dart';
import 'package:flutter/material.dart';
import 'package:wazeloquent/wazeloquent.dart';

void main() async {
  var db = DB.instance;

  WidgetsFlutterBinding.ensureInitialized();

  // You can use existing db by specify file path and file name.
  // var path = await getApplicationDocumentsDirectory();
  // var dir = path.absolute.path + '/test';
  // db.setFilePath(dir, shouldForceCreatePath: true);

  db.setDbVersion(1); // set db version
  db.setFileName('test.db'); // set file
  db.onCreate([
    UserEloquent.onCreate,
    CarEloquent.onCreate,
    StudentEloquent.onCreate,
    ClassEloquent.onCreate
  ]);
  db.onOpen([
    UserEloquent.onOpen,
    CarEloquent.onOpen,
    StudentEloquent.onOpen,
    ClassEloquent.onOpen
  ]);

  db.onConfigure([
    Future(() {
      return (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      };
    })
  ]);
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

List<Widget> pages = [
  const Basic(),
  const OneToOneWidget(),
  const OneToManyWidget(),
  const ManyToManyWidget(),
];

class _MyHomePageState extends State<MyHomePage> {
  List<User> users = [];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: pages.length,
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            bottom: const TabBar(tabs: [
              Tab(
                child: Text('Basic'),
              ),
              Tab(child: Text('One To One')),
              Tab(child: Text('One To Many')),
              Tab(child: Text('Many To Many')),
            ]),
          ),
          body: TabBarView(children: pages)),
    );
  }
}
