import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/session_repository.dart';
import 'providers/scan_provider.dart';
import 'providers/session_provider.dart';
import 'providers/teaching_provider.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SessionRepository.create();

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => TeachingProvider(repository)),
        ChangeNotifierProvider(create: (_) => SessionProvider(repository)),
      ],
      child: const RubiksTeacherApp(),
    ),
  );
}
