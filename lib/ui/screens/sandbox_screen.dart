import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/cube/facelets.dart';
import '../../domain/cube/move_applier.dart';
import '../../domain/models/move.dart';
import '../theme/app_theme.dart';
import '../widgets/face_grid.dart';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  Facelets _cube = FaceletConstants.createSolved();
  int _activeFace = 0; // 0: U, 1: R, 2: F, 3: D, 4: L, 5: B

  static const _faceNames = ['Up (White)', 'Right (Red)', 'Front (Green)', 'Down (Yellow)', 'Left (Orange)', 'Back (Blue)'];

  void _apply(Move move) {
    setState(() {
      _cube = MoveApplier.apply(_cube, move);
    });
  }

  void _scramble() {
    final rand = Random();
    var state = _cube;
    for (int i = 0; i < 20; i++) {
      final move = Move.values[rand.nextInt(Move.values.length)];
      state = MoveApplier.apply(state, move);
    }
    setState(() {
      _cube = state;
    });
  }

  void _reset() {
    setState(() {
      _cube = FaceletConstants.createSolved();
    });
  }

  @override
  Widget build(BuildContext context) {
    final faceColors = _cube.sublist(_activeFace * 9, _activeFace * 9 + 9);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Sandbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Solved',
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Face Selector Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(6, (i) {
                    final isSelected = _activeFace == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_faceNames[i]),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _activeFace = i),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // Active Face View
              Container(
                width: 260,
                height: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: FaceGrid(faceColors: faceColors),
              ),

              const SizedBox(height: 24),

              // Move Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _MoveBtn(label: 'U', onTap: () => _apply(Move.U)),
                  _MoveBtn(label: "U'", onTap: () => _apply(Move.Ui)),
                  _MoveBtn(label: 'D', onTap: () => _apply(Move.D)),
                  _MoveBtn(label: "D'", onTap: () => _apply(Move.Di)),
                  _MoveBtn(label: 'R', onTap: () => _apply(Move.R)),
                  _MoveBtn(label: "R'", onTap: () => _apply(Move.Ri)),
                  _MoveBtn(label: 'L', onTap: () => _apply(Move.L)),
                  _MoveBtn(label: "L'", onTap: () => _apply(Move.Li)),
                  _MoveBtn(label: 'F', onTap: () => _apply(Move.F)),
                  _MoveBtn(label: "F'", onTap: () => _apply(Move.Fi)),
                  _MoveBtn(label: 'B', onTap: () => _apply(Move.B)),
                  _MoveBtn(label: "B'", onTap: () => _apply(Move.Bi)),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scramble,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Scramble Cube (20 moves)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MoveBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
