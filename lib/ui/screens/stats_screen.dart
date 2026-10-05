import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics & History')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StatCard(
              title: 'Total Solves Completed',
              value: '14',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.success,
            ),
            const SizedBox(height: 14),
            _StatCard(
              title: 'Best Solve Time',
              value: '1m 24s',
              icon: Icons.flash_on_rounded,
              color: AppTheme.warning,
            ),
            const SizedBox(height: 14),
            _StatCard(
              title: 'Average Time (Ao5)',
              value: '1m 48s',
              icon: Icons.timer_outlined,
              color: AppTheme.primaryLight,
            ),
            const SizedBox(height: 24),
            Text(
              'Stage Completion Rate',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            _StageProgressItem(stageName: 'Stage 1: White Cross', progress: 1.0),
            _StageProgressItem(stageName: 'Stage 2: White Corners', progress: 1.0),
            _StageProgressItem(stageName: 'Stage 3: Middle Edges', progress: 0.9),
            _StageProgressItem(stageName: 'Stage 4: Yellow Cross', progress: 0.85),
            _StageProgressItem(stageName: 'Stage 5: Orient Corners', progress: 0.75),
            _StageProgressItem(stageName: 'Stage 6: Permute Corners', progress: 0.7),
            _StageProgressItem(stageName: 'Stage 7: Permute Edges', progress: 0.65),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageProgressItem extends StatelessWidget {
  final String stageName;
  final double progress;

  const _StageProgressItem({required this.stageName, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stageName, style: Theme.of(context).textTheme.bodyMedium),
              Text('${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryLight)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.borderDark,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
