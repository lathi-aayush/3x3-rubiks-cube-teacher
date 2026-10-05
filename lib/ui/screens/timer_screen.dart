import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../theme/app_theme.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProv = context.watch<SessionProvider>();
    final seconds = sessionProv.elapsedSeconds;
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: const Text('Speed Timer')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  '$mins:$secs',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  sessionProv.isRunning ? 'Solving...' : 'Press Start or tap anywhere',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: sessionProv.resetTimer,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (sessionProv.isRunning) {
                          sessionProv.pauseTimer();
                        } else {
                          sessionProv.startTimer();
                        }
                      },
                      child: Text(sessionProv.isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
