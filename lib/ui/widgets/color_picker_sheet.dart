import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ColorPickerSheet extends StatelessWidget {
  final int currentColor;
  final void Function(int colorIndex) onColorSelected;

  const ColorPickerSheet({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  static const _names = ['White', 'Yellow', 'Green', 'Blue', 'Red', 'Orange'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Select Sticker Color',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(6, (i) {
              final isSelected = currentColor == i;
              return GestureDetector(
                onTap: () {
                  onColorSelected(i);
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.cubeColor(i),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : AppTheme.borderDark,
                          width: isSelected ? 3.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: i == 0 || i == 1 ? Colors.black : Colors.white,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _names[i],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
