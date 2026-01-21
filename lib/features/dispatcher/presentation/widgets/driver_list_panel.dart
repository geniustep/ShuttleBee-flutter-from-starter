import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart';
import '../bloc/tracking_monitor_cubit.dart';
import '../models/tracked_vehicle.dart';

/// 📋 Driver List Panel Widget - لوحة قائمة السائقين
///
/// تعرض قائمة قابلة للتمرير للمركبات/السائقين المتتبعين مع:
/// - تحديثات الحالة في الوقت الحقيقي
/// - خيارات الفلترة
/// - وظيفة البحث
/// - طلب الموقع عند الطلب
/// - خيارات الترتيب
class DriverListPanel extends StatefulWidget {
  final TrackingMonitorCubit cubit;
  final Function(TrackedVehicle) onDriverSelected;
  final Future<void> Function(int driverId) onRequestLocation;

  const DriverListPanel({
    super.key,
    required this.cubit,
    required this.onDriverSelected,
    required this.onRequestLocation,
  });

  @override
  State<DriverListPanel> createState() => _DriverListPanelState();
}

class _DriverListPanelState extends State<DriverListPanel>
    with SingleTickerProviderStateMixin {
  StreamSubscription<Map<int, TrackedVehicle>>? _vehiclesSubscription;
  StreamSubscription<TrackedVehicle?>? _selectedVehicleSubscription;
  StreamSubscription<VehicleFilter>? _filterSubscription;

  TrackedVehicle? _selectedVehicle;
  VehicleFilter _currentFilter = VehicleFilter.all;
  String _searchQuery = '';
  VehicleSortOption _sortOption = VehicleSortOption.name;
  bool _isRequestingLocation = false;
  int? _requestingDriverId;
  Timer? _debounceTimer;
  
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    _setupListeners();
  }

  void _setupListeners() {
    _vehiclesSubscription = widget.cubit.vehiclesStream.distinct().listen((vehicles) {
      debugPrint('📋 DriverListPanel: استلام ${vehicles.length} مركبة');
      if (mounted) {
        setState(() {});
      }
    });

    _selectedVehicleSubscription =
        widget.cubit.selectedVehicleStream.distinct().listen((vehicle) {
      if (mounted) {
        setState(() {
          _selectedVehicle = vehicle;
        });
      }
    });

    _filterSubscription = widget.cubit.filterStream.distinct().listen((filter) {
      if (mounted) {
        setState(() {
          _currentFilter = filter;
        });
      }
    });
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _selectedVehicleSubscription?.cancel();
    _filterSubscription?.cancel();
    _listAnimationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<TrackedVehicle> _getFilteredAndSortedVehicles() {
    var vehicles = widget.cubit.getFilteredVehicles().values.toList();

    // تطبيق فلتر البحث
    if (_searchQuery.isNotEmpty) {
      vehicles = vehicles.where((v) {
        final query = _searchQuery.toLowerCase();
        return v.vehicleName.toLowerCase().contains(query) ||
            v.driverName.toLowerCase().contains(query) ||
            v.licensePlate?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // الترتيب
    switch (_sortOption) {
      case VehicleSortOption.name:
        vehicles.sort((a, b) => a.vehicleName.compareTo(b.vehicleName));
        break;
      case VehicleSortOption.status:
        vehicles.sort((a, b) => a.statusText.compareTo(b.statusText));
        break;
      case VehicleSortOption.lastUpdate:
        vehicles.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
        break;
    }

    return vehicles;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildVehicleList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.dispatcherGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'السائقين والمركبات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
                StreamBuilder<int>(
                  stream: widget.cubit.onlineVehiclesCountStream,
                  initialData: 0,
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data! : 0;
                    return Text(
                      '$count متصل',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Cairo',
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          PopupMenuButton<VehicleSortOption>(
            icon: Icon(Icons.sort_rounded, color: AppColors.dispatcherPrimary),
            tooltip: 'ترتيب حسب',
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: VehicleSortOption.name,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, 
                        color: _sortOption == VehicleSortOption.name 
                            ? AppColors.dispatcherPrimary : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('الاسم', 
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: _sortOption == VehicleSortOption.name 
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: VehicleSortOption.status,
                child: Row(
                  children: [
                    Icon(Icons.traffic_rounded, 
                        color: _sortOption == VehicleSortOption.status 
                            ? AppColors.dispatcherPrimary : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('الحالة', 
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: _sortOption == VehicleSortOption.status 
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                  ],
                ),
              ),
              PopupMenuItem(
                value: VehicleSortOption.lastUpdate,
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, 
                        color: _sortOption == VehicleSortOption.lastUpdate 
                            ? AppColors.dispatcherPrimary : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('آخر تحديث', 
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: _sortOption == VehicleSortOption.lastUpdate 
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        label: 'البحث عن سائقين أو مركبات',
        child: TextField(
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'البحث عن سائق أو مركبة...',
            hintStyle: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.dispatcherPrimary.withValues(alpha: 0.7),
              semanticLabel: 'أيقونة البحث',
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppColors.textSecondary,
                      semanticLabel: 'مسح البحث',
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      if (PlatformUtils.supportsHapticFeedback) {
                        HapticFeedback.lightImpact();
                      }
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.dispatcherPrimary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(fontFamily: 'Cairo'),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _searchQuery = value;
                });
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: VehicleFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(
                _getFilterLabel(filter),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                widget.cubit.setFilter(filter);
                if (PlatformUtils.supportsHapticFeedback) {
                  HapticFeedback.selectionClick();
                }
              },
              avatar: Icon(
                _getFilterIcon(filter),
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.dispatcherPrimary,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.dispatcherPrimary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(VehicleFilter filter) {
    switch (filter) {
      case VehicleFilter.all:
        return 'الكل';
      case VehicleFilter.online:
        return 'متصل';
      case VehicleFilter.offline:
        return 'غير متصل';
      case VehicleFilter.onTrip:
        return 'في رحلة';
      case VehicleFilter.available:
        return 'متاح';
    }
  }

  IconData _getFilterIcon(VehicleFilter filter) {
    switch (filter) {
      case VehicleFilter.all:
        return Icons.grid_view_rounded;
      case VehicleFilter.online:
        return Icons.wifi_rounded;
      case VehicleFilter.offline:
        return Icons.wifi_off_rounded;
      case VehicleFilter.onTrip:
        return Icons.local_shipping_rounded;
      case VehicleFilter.available:
        return Icons.check_circle_rounded;
    }
  }

  Widget _buildVehicleList() {
    final vehicles = _getFilteredAndSortedVehicles();

    if (vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'لا توجد مركبات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'جرب تعديل بحثك'
                    : 'في انتظار تحديثات المركبات...',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Cairo',
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (PlatformUtils.supportsHapticFeedback) {
          HapticFeedback.mediumImpact();
        }
      },
      color: AppColors.dispatcherPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vehicles.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border.withValues(alpha: 0.5),
          indent: 76,
        ),
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          final isSelected = _selectedVehicle?.vehicleId == vehicle.vehicleId;
          final isRequesting = _isRequestingLocation && _requestingDriverId == vehicle.driverId;

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _listAnimationController,
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                (0.5 + index * 0.1).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            )),
            child: FadeTransition(
              opacity: _listAnimationController,
              child: _VehicleListItem(
                vehicle: vehicle,
                isSelected: isSelected,
                isRequestingLocation: isRequesting,
                onTap: () {
                  if (PlatformUtils.supportsHapticFeedback) {
                    HapticFeedback.selectionClick();
                  }
                  widget.onDriverSelected(vehicle);
                },
                onRequestLocation: () async {
                  setState(() {
                    _isRequestingLocation = true;
                    _requestingDriverId = vehicle.driverId;
                  });
                  if (PlatformUtils.supportsHapticFeedback) {
                    HapticFeedback.mediumImpact();
                  }
                  try {
                    await widget.onRequestLocation(vehicle.driverId);
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isRequestingLocation = false;
                        _requestingDriverId = null;
                      });
                    }
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VehicleListItem extends StatelessWidget {
  final TrackedVehicle vehicle;
  final bool isSelected;
  final bool isRequestingLocation;
  final VoidCallback onTap;
  final Future<void> Function() onRequestLocation;

  const _VehicleListItem({
    required this.vehicle,
    required this.isSelected,
    required this.isRequestingLocation,
    required this.onTap,
    required this.onRequestLocation,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Semantics(
      label: '${vehicle.vehicleName}، السائق ${vehicle.driverName}، الحالة ${_getArabicStatus()}',
      selected: isSelected,
      child: Material(
        color: isSelected
            ? AppColors.dispatcherPrimaryLight.withValues(alpha: 0.15)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isSelected
                ? BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: AppColors.dispatcherPrimary,
                        width: 3,
                      ),
                    ),
                  )
                : null,
            child: Row(
              children: [
                // مؤشر الحالة
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor,
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: Icon(
                    vehicle.isOnTrip ? Icons.local_shipping_rounded : Icons.person_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 14),

                // معلومات المركبة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.driverName,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getArabicStatus(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.formattedTimeSinceUpdate,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // زر الإجراء
                if (!vehicle.isOnline || vehicle.isStale)
                  isRequestingLocation
                      ? SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.dispatcherPrimary,
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.location_searching_rounded,
                            color: AppColors.dispatcherPrimary,
                          ),
                          iconSize: 22,
                          tooltip: 'طلب الموقع',
                          onPressed: onRequestLocation,
                        )
                else
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    semanticLabel: 'عرض التفاصيل',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getArabicStatus() {
    switch (vehicle.statusColor) {
      case VehicleStatusColor.onTrip:
        return 'في رحلة';
      case VehicleStatusColor.available:
        return 'متاح';
      case VehicleStatusColor.busy:
        return 'مشغول';
      case VehicleStatusColor.offline:
        return 'غير متصل';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor() {
    switch (vehicle.statusColor) {
      case VehicleStatusColor.onTrip:
        return AppColors.success;
      case VehicleStatusColor.available:
        return AppColors.info;
      case VehicleStatusColor.busy:
        return AppColors.secondary;
      case VehicleStatusColor.offline:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

enum VehicleSortOption {
  name,
  status,
  lastUpdate,
}
