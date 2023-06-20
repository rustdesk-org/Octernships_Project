import 'package:flutter/material.dart';
import 'ffi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Octernships Project',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
          const MyHomePage(title: 'Elevate priviledge to run a Linux command'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String username = "";
  String dir = "";

  Future<void> getUser() async {
    await api.getUsername().then((value) {
      setState(() {
        username = value;
      });
    });
  }

  Future<void> returnFolder(String password) async {
    await api.printRootFolder(password: password).then((value) {
      setState(() {
        dir = value!;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
                onPressed: () {
                  passwordDialog();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text(
                  "Show my Home Folder",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white),
                )),
          ),
          const SizedBox(height: 10),
          Text(
            dir,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
          )
        ],
      ),
    );
  }

  void passwordDialog() {
    showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          String password = "";
          return AlertDialog(
            backgroundColor: const Color(0xFFE0E0E0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("[sudo] enter password for $username: "),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                height: 40,
                child: TextField(
                  onChanged: (value) {
                    password = value;
                  },
                  obscureText: true,
                ),
              )
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back"),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    dir = "";
                  });
                  await returnFolder(password).then((value) {
                    if (dir.isEmpty) {
                      final snackbar = SnackBar(
                        backgroundColor: Colors.red,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15))),
                        content: const Text(
                          "Incorrect Password, Please try again",
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                        action:
                            SnackBarAction(label: 'Close', onPressed: () {}),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(snackbar);
                    } else {
                      Navigator.pop(context);
                    }
                  });
                },
                child: const Text("Next"),
              )
            ],
          );
        });
  }
}
