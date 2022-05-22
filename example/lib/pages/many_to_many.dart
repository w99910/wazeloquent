import 'package:example/eloquents/country.dart';
import 'package:example/models/country.dart';
import 'package:flutter/material.dart';

class ManyToManyWidget extends StatefulWidget {
  const ManyToManyWidget({Key? key}) : super(key: key);

  @override
  State<ManyToManyWidget> createState() => _ManyToManyWidgetState();
}

class _ManyToManyWidgetState extends State<ManyToManyWidget> {
  final CountryEloquent countryEloquent = CountryEloquent();

  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    var country = Country(id: 1, name: 'UK');
    await country.save();
    country.users();
    print(await countryEloquent.all());
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
