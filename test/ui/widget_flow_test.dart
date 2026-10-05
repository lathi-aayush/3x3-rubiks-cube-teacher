import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rubiks_cube_teacher/data/session_repository.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/models/cube_color.dart';
import 'package:rubiks_cube_teacher/providers/scan_provider.dart';
import 'package:rubiks_cube_teacher/providers/teaching_provider.dart';
import 'package:rubiks_cube_teacher/providers/session_provider.dart';
import 'package:rubiks_cube_teacher/ui/screens/home_screen.dart';
import 'package:rubiks_cube_teacher/ui/screens/correction_screen.dart';
import 'package:rubiks_cube_teacher/ui/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp(Widget child, SharedPreferences prefs, {ScanProvider? scanProvider}) {
    final repo = SessionRepository(prefs);
    final scan = scanProvider ?? ScanProvider();
    final teaching = TeachingProvider(repo);
    final session = SessionProvider(repo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ScanProvider>.value(value: scan),
        ChangeNotifierProvider<TeachingProvider>.value(value: teaching),
        ChangeNotifierProvider<SessionProvider>.value(value: session),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  testWidgets('HomeScreen renders key options and title', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(createTestApp(const HomeScreen(), prefs));
    await tester.pumpAndSettle();

    expect(find.text('Cube Teacher'), findsOneWidget);
    expect(find.text('Scan Your Cube'), findsOneWidget);
    expect(find.text('Speed Timer'), findsOneWidget);
    expect(find.text('Sandbox'), findsOneWidget);
    expect(find.text('Statistics & History'), findsOneWidget);
  });

  testWidgets('CorrectionScreen renders face tabs and validation status', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final scan = ScanProvider();
    // Load solved cube
    for (int i = 0; i < 54; i++) {
      scan.updateFacelet(i, FaceletConstants.solved[i]);
    }

    await tester.pumpWidget(createTestApp(const CorrectionScreen(), prefs, scanProvider: scan));
    await tester.pumpAndSettle();

    // Verify title and tabs
    expect(find.text('Verify & Correct Colors'), findsOneWidget);
    expect(find.text('Up (White)'), findsOneWidget);
    expect(find.text('Down (Yellow)'), findsOneWidget);
    expect(find.text('Front (Green)'), findsOneWidget);
    expect(find.text('Back (Blue)'), findsOneWidget);
    expect(find.text('Left (Orange)'), findsOneWidget);
    expect(find.text('Right (Red)'), findsOneWidget);

    // Validation should be valid
    expect(find.text('Cube configuration is valid! Ready to learn.'), findsOneWidget);
    expect(find.text('Start Solving Lesson'), findsOneWidget);

    // Now introduce an error: set sticker 0 to red (index 4)
    scan.updateFacelet(0, 4);
    await tester.pumpAndSettle();

    // Now validation should fail
    expect(find.text('Cube configuration is valid! Ready to learn.'), findsNothing);
    expect(find.textContaining('Each color must appear exactly 9 times'), findsOneWidget);
  });
}
