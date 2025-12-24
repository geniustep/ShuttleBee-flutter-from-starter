import 'package:flutter/material.dart';

import '../bloc/tracking_monitor_cubit.dart';

/// Tracking Controls Widget
///
/// Floating controls for map interactions:
/// - Zoom in/out
/// - Fit all vehicles
/// - Refresh connection
/// - Toggle traffic
/// - My location
class TrackingControls extends StatefulWidget {
  final TrackingMonitorCubit cubit;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const TrackingControls({
    Key? key,
    required this.cubit,
    required this.onRefresh,
    this.isRefreshing = false,
  }) : super(key: key);

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
      label: 'Map controls',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            context,
            icon: Icons.center_focus_strong,
            tooltip: 'Fit all vehicles',
            onPressed: () => widget.cubit.fitAllVehicles(),
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            context,
            icon: Icons.refresh,
            tooltip: 'Refresh connection',
            onPressed: widget.onRefresh,
            isLoading: widget.isRefreshing,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            context,
            icon: Icons.clear_all,
            tooltip: 'Clear offline vehicles',
            onPressed: () => widget.cubit.clearOfflineVehicles(),
          ),
        ],
      ),
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
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          onTap: isLoading ? null : () {
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
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                      semanticLabel: tooltip,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
