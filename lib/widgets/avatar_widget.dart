import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AvatarWidget extends StatefulWidget {
  final String mood; // 'happy', 'neutral', 'tired'

  const AvatarWidget({super.key, this.mood = 'neutral'});

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;
  late Animation<double> _auraAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _bounceAnim = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _auraAnim = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Aura glow
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: _auraAnim.value),
                ),
              ),
              // Main avatar circle
              Transform.translate(
                offset: Offset(0, _bounceAnim.value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Eyes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEye(),
                          const SizedBox(width: 12),
                          _buildEye(),
                        ],
                      ),
                      // Mouth
                      Positioned(
                        bottom: 20,
                        child: _buildMouth(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEye() {
    final scaleY = widget.mood == 'tired' ? 0.3 : 1.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8 * scaleY,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMouth() {
    switch (widget.mood) {
      case 'happy':
        return Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
        );
      case 'tired':
        return Container(
          width: 6,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      default:
        return Container(
          width: 10,
          height: 1.5,
          color: Colors.white.withValues(alpha: 0.8),
        );
    }
  }
}
