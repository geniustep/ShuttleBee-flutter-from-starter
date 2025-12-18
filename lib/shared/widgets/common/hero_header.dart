import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../l10n/app_localizations.dart';

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
      actions:
          actions.map((action) => _buildHeaderButton(action, context)).toList(),
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

            // === Decorative Blobs ===
            if (context.isDesktop) ...[
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // === Content ===
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsive(
                      mobile: double.infinity,
                      tablet: 900,
                      desktop: 1400,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(
                        mobile: 20.0,
                        tablet: 32.0,
                        desktop: 48.0,
                      ),
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // === Online Badge ===
                        if (showOnlineIndicator) _buildOnlineBadge(context),
                        if (showOnlineIndicator)
                          SizedBox(
                            height: context.responsive(
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),

                        // === Welcome Text ===
                        Text(
                          userName != null ? '$title، $userName 👋' : title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive(
                              mobile: 26.0,
                              tablet: 30.0,
                              desktop: 36.0,
                            ),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            height: 1.2,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: context.responsive(
                                  mobile: 4.0,
                                  tablet: 6.0,
                                  desktop: 8.0,
                                ),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: context.responsive(
                            mobile: 4.0,
                            tablet: 6.0,
                            desktop: 8.0,
                          ),
                        ),

                        // === Subtitle ===
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white70,
                              size: context.responsive(
                                mobile: 14.0,
                                tablet: 16.0,
                                desktop: 18.0,
                              ),
                            ),
                            SizedBox(
                              width: context.responsive(
                                mobile: 6.0,
                                tablet: 8.0,
                                desktop: 10.0,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: context.responsive(
                                  mobile: 14.0,
                                  tablet: 15.0,
                                  desktop: 16.0,
                                ),
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // === Bottom Widget ===
                        if (bottomWidget != null) ...[
                          SizedBox(
                            height: context.responsive(
                              mobile: 12.0,
                              tablet: 14.0,
                              desktop: 16.0,
                            ),
                          ),
                          bottomWidget!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(
          mobile: 12.0,
          tablet: 14.0,
          desktop: 16.0,
        ),
        vertical: context.responsive(
          mobile: 6.0,
          tablet: 7.0,
          desktop: 8.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(
          context.responsive(
            mobile: 20.0,
            tablet: 22.0,
            desktop: 24.0,
          ),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onlineIndicatorController != null)
            AnimatedBuilder(
              animation: onlineIndicatorController!,
              builder: (context, child) {
                return Container(
                  width: context.responsive(
                    mobile: 8.0,
                    tablet: 9.0,
                    desktop: 10.0,
                  ),
                  height: context.responsive(
                    mobile: 8.0,
                    tablet: 9.0,
                    desktop: 10.0,
                  ),
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
              width: context.responsive(
                mobile: 8.0,
                tablet: 9.0,
                desktop: 10.0,
              ),
              height: context.responsive(
                mobile: 8.0,
                tablet: 9.0,
                desktop: 10.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(
            width: context.responsive(
              mobile: 8.0,
              tablet: 9.0,
              desktop: 10.0,
            ),
          ),
          Text(
            AppLocalizations.of(context).onlineNow,
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive(
                mobile: 12.0,
                tablet: 13.0,
                desktop: 14.0,
              ),
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(HeroHeaderAction action, BuildContext context) {
    final buttonSize = context.responsive(
      mobile: 40.0,
      tablet: 44.0,
      desktop: 48.0,
    );

    final iconSize = context.responsive(
      mobile: 22.0,
      tablet: 24.0,
      desktop: 26.0,
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.responsive(
          mobile: 4.0,
          tablet: 5.0,
          desktop: 6.0,
        ),
      ),
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: action.isLoading
            ? SizedBox(
                width: iconSize * 0.8,
                height: iconSize * 0.8,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(action.icon, color: Colors.white, size: iconSize),
        onPressed: action.isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                action.onPressed?.call();
              },
        tooltip: action.tooltip,
        splashRadius: buttonSize / 2,
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
    Color(0xFF8B5CF6), // Purple 500 - محدّث
    Color(0xFF7C3AED), // Purple 600
    Color(0xFF6D28D9), // Purple 700
  ];

  static const List<Color> passenger = [
    Color(0xFF388E3C),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
  ];
}
