import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_template/screens/screens.dart';
import 'package:google_fonts/google_fonts.dart';

import '../globals.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool isVisible = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: FadeTransition(
                opacity: _animation,
                child: Text(
                  "Welcome, $username.",
                  style: GoogleFonts.nunito(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: Visibility(
                  visible: isVisible,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                      "This little application of mine will help you elevate privilege and display your root folder within this app.",
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          color: const Color(0xFFBDBDBD),
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  if (!isVisible) {
                    setState(() {
                      isVisible = true;
                    });
                  } else {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => const SudoCommandPage())));
                  }
                },
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(25),
                    shape: const CircleBorder(),
                    backgroundColor: Colors.lightBlue),
                child: Text(
                  "→",
                  style: GoogleFonts.nunito(
                      fontSize: 25,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Center(
            //     child: RichText(
            //         text: TextSpan(
            //             text: "How does it work?",
            //             style: GoogleFonts.nunito(
            //                 decoration: TextDecoration.underline,
            //                 fontSize: 14,
            //                 color: Colors.blue,
            //                 fontWeight: FontWeight.w600),
            //             recognizer: TapGestureRecognizer()..onTap = () {})))
          ]),
    );
  }
}
