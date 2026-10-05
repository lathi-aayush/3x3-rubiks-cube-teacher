import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/correction_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sandbox_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/teaching_screen.dart';
import 'screens/timer_screen.dart';
import 'theme/app_theme.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/correction',
      builder: (context, state) => const CorrectionScreen(),
    ),
    GoRoute(
      path: '/teach',
      builder: (context, state) => const TeachingScreen(),
    ),
    GoRoute(
      path: '/timer',
      builder: (context, state) => const TimerScreen(),
    ),
    GoRoute(
      path: '/sandbox',
      builder: (context, state) => const SandboxScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsScreen(),
    ),
  ],
);

class RubiksTeacherApp extends StatelessWidget {
  const RubiksTeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "3x3 Rubik's Cube Teacher",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
