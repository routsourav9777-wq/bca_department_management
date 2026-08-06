import 'dart:async';

import 'package:flutter/material.dart';

// Login Screen import karo
import '../auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// Background Image
          Image.asset(
            "assets/images/college_building.jpeg",
            fit: BoxFit.cover,
          ),

          /// Dark Overlay
          Container(
            color: Colors.black.withOpacity(.70),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: "logo",
                      child: Image.asset(
                        "assets/images/department_logo.png",
                        width: 170,
                      ),
                    ),
                    const SizedBox(height: 35),
                    const Text(
                      "WELCOME TO",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Department of\nComputer Applications",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Salipur Autonomous College",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Salipur, Odisha",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      "Empowering Future IT Professionals",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Version 1.0",
                style: TextStyle(
                  color: Colors.white.withOpacity(.7),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
