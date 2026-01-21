import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart';
import '../bloc/tracking_monitor_cubit.dart';

/// 🎛️ Tracking Controls Widget - ويدجت أدوات التحكم
///
/// أدوات تحكم عائمة للتفاعل مع الخريطة:
/// - تكبير/تصغير
/// - احتواء جميع المركبات
/// - تحديث الاتصال
/// - تبديل حركة المرور
/// - موقعي
class TrackingControls extends StatefulWidget {
  final TrackingMonitorCubit cubit;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const TrackingControls({
    super.key,
    required this.cubit,
    required this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  State<TrackingControls> createState() => _TrackingControlsState();
}

class _TrackingControlsState extends State<TrackingControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'أدوات التحكم في الخريطة',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildControlButton(
              context,
              icon: Icons.center_focus_strong_rounded,
              tooltip: 'إظهار جميع المركبات',
              onPressed: () => widget.cubit.fitAllVehicles(),
            ),
            _buildDivider(),
            _buildControlButton(
              context,
              icon: Icons.refresh_rounded,
              tooltip: 'تحديث الاتصال',
              onPressed: widget.onRefresh,
              isLoading: widget.isRefreshing,
            ),
            _buildDivider(),
            _buildControlButton(
              context,
              icon: Icons.delete_sweep_rounded,
              tooltip: 'مسح المركبات غير المتصلة',
              onPressed: () => widget.cubit.clearOfflineVehicles(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: 32,
      color: AppColors.border.withValues(alpha: 0.5),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            if (PlatformUtils.supportsHapticFeedback) {
              HapticFeedback.lightImpact();
            }
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Tooltip(
              message: tooltip,
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
              ),
              decoration: BoxDecoration(
                color: AppColors.dispatcherPrimaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.dispatcherPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      color: AppColors.dispatcherPrimary,
                      size: 22,
                      semanticLabel: tooltip,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
