import 'package:blinking_text/blinking_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ffi.dart';

class CheckPolkit extends StatefulWidget {
  const CheckPolkit({super.key});

  @override
  State<CheckPolkit> createState() => _CheckPolkitState();
}

class _CheckPolkitState extends State<CheckPolkit> {
  bool status = true;
  bool isVisible = true;

  Future<void> checkStatus() async {
    var thing = await api.checkPolkit();
    if (thing!.isNotEmpty) {
      print("An error occured");
      setState(() {
        status = false;
      });
    } else {
      print("Polkit dey");
      setState(() {
        status = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    timer();
    checkStatus();
  }

  Future<void> timer() async {
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        isVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
          child: Visibility(
        visible: isVisible,
        replacement: Text(!status
            ? "Seems like you don't have polkit set up."
            : "We detected polkit on your system. Proceed?"),
        child: BlinkText(
          beginColor: const Color(0xFFBDBDBD),
          "Checking if your system has polkit...",
          style: GoogleFonts.nunito(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBDBDBD)),
          endColor: Colors.transparent,
        ),
      )),
    );
  }
}
