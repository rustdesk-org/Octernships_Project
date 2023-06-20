import 'package:flutter/material.dart';
import 'ffi.dart';
import 'globals.dart';
import 'screens/screens.dart';

Future<void> main() async {
  await api.getUsername().then((value) {
    username = value;
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Octernships Project',
      home: WelcomeScreen(),
    );
  }
}
