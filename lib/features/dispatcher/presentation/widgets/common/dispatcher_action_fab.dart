import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Floating Action Button for Dispatcher screens
///
/// FAB مستجيب يظهر على الهاتف فقط مع الإجراءات الرئيسية:
/// - إذا كان action واحد → FAB عادي
/// - إذا كان أكثر من واحد → FAB قابل للتوسيع (Speed Dial)
/// - لا يظهر على Tablet/Desktop (الأزرار في Header/Footer)
class DispatcherActionFAB extends StatefulWidget {
  const DispatcherActionFAB({
    super.key,
    required this.actions,
    this.showOnTablet = false,
    this.showOnDesktop = false,
  });

  /// قائمة الإجراءات
  final List<DispatcherFabAction> actions;

  /// إظهار على الـ Tablet
  final bool showOnTablet;

  /// إظهار على الـ Desktop
  final bool showOnDesktop;

  @override
  State<DispatcherActionFAB> createState() => _DispatcherActionFABState();
}

class _DispatcherActionFABState extends State<DispatcherActionFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // التحقق من إظهار الـ FAB حسب نوع الجهاز
    if (context.isDesktop && !widget.showOnDesktop) {
      return const SizedBox.shrink();
    }
    if (context.isTablet && !widget.showOnTablet) {
      return const SizedBox.shrink();
    }

    // لا يوجد actions
    if (widget.actions.isEmpty) {
      return const SizedBox.shrink();
    }

    // إذا كان action واحد فقط → FAB بسيط
    if (widget.actions.length == 1) {
      return _buildSingleFAB(context, widget.actions.first);
    }

    // أكثر من action → Speed Dial FAB
    return _buildSpeedDialFAB(context);
  }

  Widget _buildSingleFAB(BuildContext context, DispatcherFabAction action) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        action.onPressed?.call();
      },
      backgroundColor: action.backgroundColor ?? AppColors.dispatcherPrimary,
      foregroundColor: action.foregroundColor ?? Colors.white,
      icon: Icon(action.icon),
      label: Text(
        action.label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildSpeedDialFAB(BuildContext context) {
    final primaryAction = widget.actions.first;
    final secondaryActions = widget.actions.skip(1).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // === Secondary Actions (Expanded) ===
        ...secondaryActions.asMap().entries.map((entry) {
          final action = entry.value;

          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final slideValue = _expandAnimation.value;
              final opacity = slideValue;
              final translateY = (1 - slideValue) * 20;

              if (opacity == 0) return const SizedBox.shrink();

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Label
                        Material(
                          color: Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              action.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Mini FAB
                        FloatingActionButton.small(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _toggle();
                            action.onPressed?.call();
                          },
                          backgroundColor:
                              action.backgroundColor ?? AppColors.dispatcherPrimaryLight,
                          foregroundColor:
                              action.foregroundColor ?? AppColors.dispatcherPrimary,
                          elevation: 2,
                          child: Icon(action.icon, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // === Primary FAB (Main toggle) ===
        FloatingActionButton.extended(
          onPressed: () {
            if (widget.actions.length > 1) {
              _toggle();
            } else {
              HapticFeedback.mediumImpact();
              primaryAction.onPressed?.call();
            }
          },
          backgroundColor:
              primaryAction.backgroundColor ?? AppColors.dispatcherPrimary,
          foregroundColor: primaryAction.foregroundColor ?? Colors.white,
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0, // 45 degrees
            duration: const Duration(milliseconds: 250),
            child: Icon(_isExpanded ? Icons.close_rounded : primaryAction.icon),
          ),
          label: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _isExpanded ? 'إغلاق' : primaryAction.label,
              key: ValueKey(_isExpanded),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          elevation: _isExpanded ? 8 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

/// FAB Action Data
class DispatcherFabAction {
  const DispatcherFabAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isPrimary;
}
