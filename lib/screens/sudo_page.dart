import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ffi.dart';
import '../globals.dart';

class SudoCommandPage extends StatefulWidget {
  const SudoCommandPage({Key? key}) : super(key: key);

  @override
  State<SudoCommandPage> createState() => _SudoCommandPageState();
}

class _SudoCommandPageState extends State<SudoCommandPage> {
  String dir = "";

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
                  "Show me my Root Folder",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white),
                )),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF5F5F5),
            ),
            child: Text(
              dir,
              style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
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
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFFE0E0E0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: const Text('Incorrect Password'),
                            content: const Text('Please try again.'),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                              ),
                            ],
                          );
                        },
                      );
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
