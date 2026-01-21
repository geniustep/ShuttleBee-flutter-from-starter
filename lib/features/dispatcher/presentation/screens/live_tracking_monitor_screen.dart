import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import '../../../../core/config/company_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../vehicles/data/datasources/vehicle_remote_data_source.dart';
import '../../../shuttlebee/data/services/shuttlebee_api_service.dart';
import '../widgets/tracking_map_widget.dart';
import '../widgets/driver_list_panel.dart';
import '../widgets/tracking_controls.dart';
import '../widgets/connection_status_indicator.dart';
import '../bloc/tracking_monitor_cubit.dart';

/// 📍 Live Tracking Monitor Screen - شاشة التتبع الحي
///
/// واجهة تتبع احترافية محسّنة لجميع المنصات:
/// - 📱 Mobile (Portrait & Landscape)
/// - 📲 Tablet (Adaptive layout)
/// - 🖥️ Desktop (Multi-panel view)
/// - 🌐 Web (Responsive design)
///
/// المميزات:
/// - تتبع المركبات في الوقت الحقيقي
/// - مراقبة حالة السائقين
/// - طلب الموقع عند الطلب
/// - مؤشر حالة الاتصال
/// - تخطيط responsive متكيف
/// - انيميشن سلسة
/// - تحميل المركبات من السيرفر
class LiveTrackingMonitorScreen extends StatefulWidget {
  final int dispatcherId;
  final int? companyId;
  final LiveTrackingService trackingService;
  final VehicleRemoteDataSource? vehicleDataSource;
  final ShuttleBeeApiService? shuttleBeeApiService;

  const LiveTrackingMonitorScreen({
    super.key,
    required this.dispatcherId,
    this.companyId,
    required this.trackingService,
    this.vehicleDataSource,
    this.shuttleBeeApiService,
  });

  @override
  State<LiveTrackingMonitorScreen> createState() =>
      _LiveTrackingMonitorScreenState();
}

class _LiveTrackingMonitorScreenState extends State<LiveTrackingMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TrackingMonitorCubit _cubit;
  bool _isDrawerOpen = false;
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;

  // Stream subscriptions
  StreamSubscription<VehiclePosition>? _vehiclePositionSubscription;
  StreamSubscription<DriverLocation>? _locationResponseSubscription;
  StreamSubscription<DriverStatusUpdate>? _driverStatusSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;

  // UI State
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshing = false;

  // Layout responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  static const double _desktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    _cubit = TrackingMonitorCubit(
      trackingService: widget.trackingService,
      vehicleDataSource: widget.vehicleDataSource,
      shuttleBeeApiService: widget.shuttleBeeApiService,
      companyId: widget.companyId,
    );
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _drawerAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _initializeTracking();
  }

  Future<void> _initializeTracking({bool isRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (!isRefresh) {
        _isLoading = true;
      }
      _isRefreshing = isRefresh;
      _errorMessage = null;
    });

    try {
      // تحميل المركبات من السيرفر أولاً
      await _cubit.loadVehiclesFromServer();

      // الاتصال بـ WebSocket
      await widget.trackingService.connect(userId: widget.dispatcherId);

      // الاشتراك في التتبع الحي
      await widget.trackingService.subscribeLiveTracking();

      // إعداد مستمعي الـ streams
      _setupStreamListeners();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'فشل الاتصال: $e';
        });
      }
    }
  }

  void _setupStreamListeners() {
    _clearStreamListeners();

    // الاستماع لتحديثات مواقع المركبات
    _vehiclePositionSubscription = widget.trackingService.vehiclePositionStream
        .listen(
          (position) {
            _cubit.onVehiclePositionUpdate(position);
          },
          onError: (error) {
            debugPrint('خطأ في stream موقع المركبة: $error');
          },
        );

    // الاستماع لاستجابات الموقع
    _locationResponseSubscription = widget
        .trackingService
        .locationResponseStream
        .listen((location) {
          _cubit.onDriverLocationUpdate(location);
        });

    // الاستماع لتحديثات حالة السائق
    _driverStatusSubscription = widget.trackingService.driverStatusStream
        .listen((statusUpdate) {
          _cubit.onDriverStatusUpdate(statusUpdate);
        });

    // الاستماع لحالة الاتصال
    _connectionStatusSubscription = widget
        .trackingService
        .connectionStatusStream
        .listen((isConnected) {
          if (mounted) {
            setState(() {
              _isConnected = isConnected;
            });

            // Haptic feedback عند تغيير حالة الاتصال
            if (isConnected && PlatformUtils.supportsHapticFeedback) {
              HapticFeedback.mediumImpact();
            }
          }
        });
  }

  @override
  void dispose() {
    _clearStreamListeners();
    widget.trackingService.disconnect();
    _drawerAnimationController.dispose();
    _cubit.dispose();
    super.dispose();
  }

  void _clearStreamListeners() {
    _vehiclePositionSubscription?.cancel();
    _vehiclePositionSubscription = null;
    _locationResponseSubscription?.cancel();
    _locationResponseSubscription = null;
    _driverStatusSubscription?.cancel();
    _driverStatusSubscription = null;
    _connectionStatusSubscription?.cancel();
    _connectionStatusSubscription = null;
  }

  void _toggleDrawer() {
    if (!mounted) return;
    if (PlatformUtils.supportsHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
      if (_isDrawerOpen) {
        _drawerAnimationController.forward();
      } else {
        _drawerAnimationController.reverse();
      }
    });
  }

  void _closeDrawer() {
    if (!mounted) return;
    if (_isDrawerOpen) {
      setState(() {
        _isDrawerOpen = false;
        _drawerAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading;
    final errorMessage = _errorMessage;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.dispatcherBackground,
          drawerEdgeDragWidth: 0,
          body: isLoading
              ? _buildLoadingView()
              : errorMessage != null
              ? _buildErrorView()
              : _buildResponsiveLayout(context),
        ),
        // Custom drawer من اليمين
        if (!isLoading && errorMessage == null) _buildCustomRightDrawer(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Semantics(
      label: 'جاري الاتصال بخدمة التتبع',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.dispatcherBackground,
              AppColors.dispatcherPrimaryLight.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.dispatcherPrimary,
                  ),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'جاري الاتصال بخدمة التتبع...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CompanyConfig.companyName,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Semantics(
      label: 'فشل الاتصال',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.dispatcherBackground,
              AppColors.errorLight.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppColors.error,
                    semanticLabel: 'أيقونة خطأ',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'فشل الاتصال',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'خطأ غير معروف',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    if (PlatformUtils.supportsHapticFeedback) {
                      HapticFeedback.mediumImpact();
                    }
                    _initializeTracking();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dispatcherPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context) {
    // استخدام LayoutBuilder للاستجابة الفورية لتغيير الحجم
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // تحديد نوع التخطيط حسب حجم الشاشة والاتجاه
        if (screenWidth >= _desktopBreakpoint ||
            (screenWidth >= _tabletBreakpoint && isLandscape)) {
          return _buildDesktopLayout();
        } else if (screenWidth >= _mobileBreakpoint) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop layout (شاشات عريضة، multi-panel)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.border,
        ),

        // Main Content - الخريطة
        Expanded(
          child: Column(
            children: [
              ConnectionStatusIndicator(isConnected: _isConnected),
              Expanded(
                child: Stack(
                  children: [
                    TrackingMapWidget(
                      cubit: _cubit,
                      companyLocation: _cubit.companyLocation,
                    ),

                    // Floating Controls (أعلى اليسار)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: TrackingControls(
                        cubit: _cubit,
                        onRefresh: () => _initializeTracking(isRefresh: true),
                        isRefreshing: _isRefreshing,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // اللوحة اليمنى - قائمة السائقين
        Container(
          width: 380,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildTopBar(showMenuButton: false),
              Expanded(
                child: DriverListPanel(
                  cubit: _cubit,
                  onDriverSelected: (driver) {
                    _cubit.selectDriver(driver);
                    if (PlatformUtils.supportsHapticFeedback) {
                      HapticFeedback.selectionClick();
                    }
                  },
                  onRequestLocation: (driverId) async {
                    await _cubit.requestDriverLocation(driverId);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet layout (شاشات متوسطة، adaptive)
  // ---------------------------------------------------------------------------
  Widget _buildTabletLayout() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLandscape && screenWidth >= _tabletBreakpoint) {
      // Landscape: تخطيط جنب-لجنب
      return Row(
        children: [
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                _buildTopBar(showMenuButton: false),
                Expanded(
                  child: DriverListPanel(
                    cubit: _cubit,
                    onDriverSelected: (driver) {
                      _cubit.selectDriver(driver);
                      if (PlatformUtils.supportsHapticFeedback) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    onRequestLocation: (driverId) async {
                      await _cubit.requestDriverLocation(driverId);
                    },
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          Expanded(child: _buildMapWithControls()),
        ],
      );
    } else {
      // Portrait: تخطيط Drawer
      return Column(
        children: [
          _buildTopBar(showMenuButton: true),
          Expanded(child: _buildMapWithControls()),
        ],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mobile layout (شاشات صغيرة، drawer-based)
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTopBar(showMenuButton: true),
        Expanded(child: _buildMapWithControls()),
      ],
    );
  }

  Widget _buildMapWithControls() {
    return Column(
      children: [
        ConnectionStatusIndicator(isConnected: _isConnected),
        Expanded(
          child: Stack(
            children: [
              TrackingMapWidget(
                cubit: _cubit,
                companyLocation: _cubit.companyLocation,
              ),

              // Floating Controls
              Positioned(
                top: 16,
                left: 16,
                child: TrackingControls(
                  cubit: _cubit,
                  onRefresh: () => _initializeTracking(isRefresh: true),
                  isRefreshing: _isRefreshing,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar({required bool showMenuButton}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final barHeight = isSmallScreen ? 60.0 : 70.0;

    return Semantics(
      label: 'شريط التتبع الحي',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: barHeight,
        decoration: BoxDecoration(
          gradient: AppColors.dispatcherGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.dispatcherPrimary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (showMenuButton) ...[
                  // زر القائمة على اليمين لفتح drawer
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    tooltip: 'فتح قائمة السائقين',
                    onPressed: _toggleDrawer,
                  ),
                ] else
                  const SizedBox(width: 8),

                // أيقونة الموقع
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 24,
                    semanticLabel: 'أيقونة الموقع',
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التتبع الحي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Colors.white,
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: _cubit.activeVehiclesCountStream,
                        initialData: 0,
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data! : 0;
                          return Text(
                            '$count ${count == 1 ? 'مركبة نشطة' : 'مركبات نشطة'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // مؤشر الاتصال مع tooltip
                Tooltip(
                  message: _isConnected ? 'متصل' : 'غير متصل',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_isConnected ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_isConnected ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isConnected ? AppColors.success : AppColors.error,
                            boxShadow: [
                              BoxShadow(
                                color: (_isConnected ? AppColors.success : AppColors.error)
                                    .withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isConnected ? 'WS' : 'غير متصل',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRightDrawer() {
    // إظهار drawer فقط في mobile و tablet portrait
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // إخفاء drawer في desktop و tablet landscape (يستخدمون panels ثابتة)
    if (screenWidth >= _desktopBreakpoint ||
        (screenWidth >= _tabletBreakpoint && isLandscape)) {
      return const SizedBox.shrink();
    }

    final drawerWidth = screenWidth > _mobileBreakpoint
        ? (screenWidth * 0.85).clamp(320.0, 400.0)
        : screenWidth * 0.85;

    return AnimatedBuilder(
      animation: _drawerSlideAnimation,
      builder: (context, child) {
        // لا نعرض drawer عندما يكون مغلقاً تماماً
        if (!_isDrawerOpen && _drawerSlideAnimation.value == 1.0) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Backdrop
            if (_isDrawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeDrawer,
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.5 * (1 - _drawerSlideAnimation.value),
                    ),
                  ),
                ),
              ),

            // Drawer ينزلق من اليمين
            Positioned(
              right: -drawerWidth * _drawerSlideAnimation.value,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: Material(
                elevation: 16,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                color: AppColors.surface,
                child: GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      // شريط زر الإغلاق
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              Icons.people_rounded,
                              color: AppColors.dispatcherPrimary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'السائقين والمركبات',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'إغلاق',
                              color: AppColors.textSecondary,
                              onPressed: _closeDrawer,
                            ),
                          ],
                        ),
                      ),
                      // محتوى Drawer
                      Expanded(
                        child: DriverListPanel(
                          cubit: _cubit,
                          onDriverSelected: (driver) {
                            _cubit.selectDriver(driver);
                            if (PlatformUtils.supportsHapticFeedback) {
                              HapticFeedback.selectionClick();
                            }
                            _closeDrawer();
                          },
                          onRequestLocation: (driverId) async {
                            await _cubit.requestDriverLocation(driverId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
