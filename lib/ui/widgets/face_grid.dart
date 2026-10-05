import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FaceGrid extends StatelessWidget {
  final List<int> faceColors; // 9 integers (0..5 or -1 for blank)
  final void Function(int index)? onStickerTap;
  final int? selectedIndex;

  const FaceGrid({
    super.key,
    required this.faceColors,
    this.onStickerTap,
    this.selectedIndex,
  }) : assert(faceColors.length == 9);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        return Center(
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 9,
              itemBuilder: (context, i) {
                final colorVal = faceColors[i];
                final color = colorVal >= 0 && colorVal <= 5
                    ? AppTheme.cubeColor(colorVal)
                    : const Color(0xFF334155);

                final isSelected = selectedIndex == i;

                return GestureDetector(
                  onTap: onStickerTap != null ? () => onStickerTap!(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black26,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: i == 4
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
