// lib/screens/opening_page.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:bayt_alhikma/screens/home_screen.dart'; // Import Home
import 'package:bayt_alhikma/screens/login_screen.dart'; // Import Login
import 'package:bayt_alhikma/view_model/local_storage_services.dart'; // Import Service

class OpeningPage extends StatefulWidget {
  const OpeningPage({super.key});

  @override
  State<OpeningPage> createState() => _OpeningPageState();
}

class _OpeningPageState extends State<OpeningPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _leftRotation;
  late Animation<double> _rightRotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _leftRotation = Tween<double>(
      begin: 0,
      end: -math.pi / 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightRotation = Tween<double>(
      begin: 0,
      end: math.pi / 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _controller.forward();
    });

    // 1. Updated Navigation Logic
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      // Check if user exists in Hive
      final savedUser = LocalStorageService.getUserLocally();

      if (savedUser != null) {
        // User found -> Go to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // No user -> Go to Login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double opacity = (_controller.value >= 0.3) ? 1.0 : 0.0;
              return AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 500),
                child: child,
              );
            },
            child: Image.asset('images/logo_placeholder.png', width: 200),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_leftRotation.value),
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'images/screenAssets/door_2.png',
                width: screenWidth / 2,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(_rightRotation.value),
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                'images/screenAssets/door_1.png',
                width: screenWidth / 2,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
