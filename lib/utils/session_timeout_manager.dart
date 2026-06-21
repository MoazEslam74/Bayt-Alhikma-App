import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  final GlobalKey<NavigatorState> navigatorKey;

  const SessionTimeoutManager({
    Key? key,
    required this.child,
    required this.navigatorKey,
    this.timeoutDuration = const Duration(minutes: 15),
  }) : super(key: key);

  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // الدالة دي دلوقتي بتشتغل مع كل لمسة في الشاشة عشان ترستر العداد
  void _startTimer([_]) {
    _timer?.cancel();
    _timer = Timer(widget.timeoutDuration, _handleTimeout);
  }

  void _handleTimeout() {
    // لما الوقت يخلص، نتأكد الأول إن المستخدم عامل تسجيل دخول أصلاً
    // لو مش عامل تسجيل دخول (واقف بيكتب بياناته في الـ Login أو الـ Signup)، مش هنقفل التطبيق
    if (FirebaseAuth.instance.currentUser != null) {
      _closeApp();
    }
  }

  void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _startTimer, // أي ضغطة بترستر العداد
      onPointerMove: _startTimer, // أي سحبة أو سكرول بترستر العداد
      onPointerUp: _startTimer,   // لما يرفع صباعه بيرستر العداد
      child: widget.child,
    );
  }
}