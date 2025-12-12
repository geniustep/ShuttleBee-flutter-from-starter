import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// Hero Header Widget - شريط علوي احترافي موحد - ShuttleBee
/// يُستخدم في جميع الصفحات الرئيسية للأدوار المختلفة
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    required this.title,
    required this.subtitle,
    this.userName,
    this.gradientColors,
    this.actions = const [],
    this.expandedHeight = 200,
    this.showOnlineIndicator = false,
    this.onlineIndicatorController,
    this.bottomWidget,
    this.showPattern = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? userName;
  final List<Color>? gradientColors;
  final List<HeroHeaderAction> actions;
  final double expandedHeight;
  final bool showOnlineIndicator;
  final AnimationController? onlineIndicatorController;
  final Widget? bottomWidget;
  final bool showPattern;

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.9),
          AppColors.primary.withValues(alpha: 0.8),
        ];

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: colors.first,
      actions: actions.map((action) => _buildHeaderButton(action)).toList(),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // === Gradient Background ===
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),

            // === Pattern Overlay ===
            if (showPattern)
              Positioned.fill(
                child: CustomPaint(
                  painter: _HexagonPatternPainter(),
                ),
              ),

            // === Content ===
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // === Online Badge ===
                    if (showOnlineIndicator) _buildOnlineBadge(),
                    if (showOnlineIndicator) const SizedBox(height: 12),

                    // === Welcome Text ===
                    Text(
                      userName != null ? '$title، $userName 👋' : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // === Subtitle ===
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),

                    // === Bottom Widget ===
                    if (bottomWidget != null) ...[
                      const SizedBox(height: 12),
                      bottomWidget!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onlineIndicatorController != null)
            AnimatedBuilder(
              animation: onlineIndicatorController!,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(
                          alpha: 0.5 + (onlineIndicatorController!.value * 0.5),
                        ),
                        blurRadius: 4 + (onlineIndicatorController!.value * 4),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          const Text(
            'متصل الآن',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(HeroHeaderAction action) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: action.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(action.icon, color: Colors.white, size: 22),
        onPressed: action.isLoading ? null : () {
          HapticFeedback.lightImpact();
          action.onPressed?.call();
        },
        tooltip: action.tooltip,
      ),
    );
  }
}

/// Hero Header Action Button
class HeroHeaderAction {
  const HeroHeaderAction({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;
}

/// Hexagon Pattern Painter
class _HexagonPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 40.0;
    final rows = (size.height / spacing).ceil() + 1;
    final cols = (size.width / spacing).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final x = col * spacing + (row.isOdd ? spacing / 2 : 0);
        final y = row * spacing * 0.866;
        _drawHexagon(canvas, Offset(x, y), 15, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Role-specific gradient colors
class HeroGradients {
  static const List<Color> driver = [
    Color(0xFF1E88E5),
    Color(0xFF1565C0),
    Color(0xFF0D47A1),
  ];

  static const List<Color> manager = [
    Color(0xFFD32F2F),
    Color(0xFFC62828),
    Color(0xFFB71C1C),
  ];

  static const List<Color> dispatcher = [
    Color(0xFF7B1FA2),
    Color(0xFF6A1B9A),
    Color(0xFF4A148C),
  ];

  static const List<Color> passenger = [
    Color(0xFF388E3C),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
  ];
}
