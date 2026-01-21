import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../domain/entities/shuttle_vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../widgets/vehicle_form_dialog.dart';

/// نوع الترتيب
enum VehicleSortOption {
  nameAsc,
  nameDesc,
  capacityAsc,
  capacityDesc,
  tripsAsc,
  tripsDesc,
}

/// شاشة إدارة المركبات - ShuttleBee
class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _showActiveOnly = false;
  bool _onlyWithDriver = false;
  bool _onlyWithParking = false;
  VehicleSortOption _sortOption = VehicleSortOption.nameAsc;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // يمكن إضافة pagination هنا في المستقبل
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildSearchBar(),
          Expanded(child: _buildVehiclesList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة مركبة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'المركبات',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: _hasActiveFilters ? Colors.amber : Colors.white,
          ),
          onPressed: _showFiltersDialog,
          tooltip: 'فلترة',
        ),
        IconButton(
          icon: const Icon(Icons.sort_rounded),
          onPressed: _showSortDialog,
          tooltip: 'ترتيب',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.invalidate(allVehiclesProvider);
            ref.invalidate(vehicleStatsProvider);
          },
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final statsAsync = ref.watch(vehicleStatsProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.directions_bus_rounded,
              '${stats.totalVehicles}',
              'إجمالي',
            ),
            _buildStatDivider(),
            _buildStatItem(
              Icons.check_circle_rounded,
              '${stats.activeVehicles}',
              'نشطة',
            ),
            _buildStatDivider(),
            _buildStatItem(
              Icons.event_seat_rounded,
              '${stats.totalCapacity}',
              'المقاعد',
            ),
            _buildStatDivider(),
            _buildStatItem(
              Icons.person_rounded,
              '${stats.vehiclesWithDriver}',
              'مع سائق',
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (_, __) => const Center(
          child: Text(
            'خطأ في تحميل الإحصائيات',
            style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'البحث عن مركبة...',
              hintStyle: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey[400],
              ),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        // Filter chips
        if (_hasActiveFilters) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (_showActiveOnly)
                  _buildFilterChip(
                    'نشطة فقط',
                    Icons.check_circle_rounded,
                    () => setState(() => _showActiveOnly = false),
                  ),
                if (_onlyWithDriver)
                  _buildFilterChip(
                    'مع سائق',
                    Icons.person_rounded,
                    () => setState(() => _onlyWithDriver = false),
                  ),
                if (_onlyWithParking)
                  _buildFilterChip(
                    'مع موقف',
                    Icons.local_parking_rounded,
                    () => setState(() => _onlyWithParking = false),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
          ],
        ),
        onDeleted: onRemove,
        deleteIcon: const Icon(Icons.close, size: 16),
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(color: AppColors.primary),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _showActiveOnly || _onlyWithDriver || _onlyWithParking;

  Widget _buildVehiclesList() {
    final vehiclesAsync = ref.watch(allVehiclesProvider);

    return vehiclesAsync.when(
      data: (vehicles) {
        var filteredVehicles = _getFilteredAndSortedVehicles(vehicles);

        if (filteredVehicles.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allVehiclesProvider);
            ref.invalidate(vehicleStatsProvider);
          },
          color: AppColors.primary,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              context.isMobile ? 96 : 16,
            ),
            itemCount: filteredVehicles.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == filteredVehicles.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildVehicleCard(filteredVehicles[index], index);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildErrorState(error, stackTrace),
    );
  }

  Widget _buildVehicleCard(ShuttleVehicle vehicle, int index) {
    final isActive = vehicle.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/dispatcher/vehicles/${vehicle.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة المركبة
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: isActive ? AppColors.primary : Colors.grey,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'غير نشط',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (vehicle.licensePlate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vehicle.licensePlate!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // السعة
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_seat_rounded,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${vehicle.seatCapacity} مقعد',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // السائق
                        if (vehicle.hasDriver) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  vehicle.driverName ?? 'سائق',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // عدد الرحلات
                        if (vehicle.tripCount > 0) ...[
                          const Spacer(),
                          Text(
                            '${vehicle.tripCount} رحلة',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // زر المزيد
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showVehicleActions(vehicle),
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (50 * index).ms,
        );
  }

  Widget _buildErrorState(Object error, StackTrace stackTrace) {
    final errorMessage = _getErrorMessage(error);
    final isNetworkError = _isNetworkError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? 'لا يوجد اتصال بالإنترنت' : 'حدث خطأ في تحميل البيانات',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.invalidate(allVehiclesProvider);
                    ref.invalidate(vehicleStatsProvider);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'يرجى التحقق من اتصال الإنترنت';
    }
    if (errorStr.contains('timeout')) {
      return 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
    }
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى';
    }
    return error.toString().replaceAll('Exception: ', '');
  }

  bool _isNetworkError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('socket') ||
        errorStr.contains('timeout');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد مركبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف مركبات جديدة لتظهر هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }


  void _showVehicleActions(ShuttleVehicle vehicle) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('تعديل', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                _showEditVehicleDialog(vehicle);
              },
            ),
            ListTile(
              leading: Icon(
                vehicle.active
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.orange,
              ),
              title: Text(
                vehicle.active ? 'إلغاء التفعيل' : 'تفعيل',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleVehicleActive(vehicle);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(vehicle);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVehicleDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => const VehicleFormDialog(),
    ).then((success) {
      if (success == true) {
        ref.invalidate(allVehiclesProvider);
        ref.invalidate(vehicleStatsProvider);
      }
    });
  }

  void _showEditVehicleDialog(ShuttleVehicle vehicle) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => VehicleFormDialog(vehicle: vehicle),
    ).then((success) {
      if (success == true) {
        ref.invalidate(allVehiclesProvider);
        ref.invalidate(vehicleStatsProvider);
        ref.invalidate(vehicleByIdProvider(vehicle.id));
      }
    });
  }

  void _toggleVehicleActive(ShuttleVehicle vehicle) async {
    final updatedVehicle = vehicle.copyWith(active: !vehicle.active);
    await ref
        .read(vehicleActionsProvider.notifier)
        .updateVehicle(updatedVehicle);
  }

  List<ShuttleVehicle> _getFilteredAndSortedVehicles(List<ShuttleVehicle> vehicles) {
    var filtered = vehicles;

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (v) =>
                v.name.toLowerCase().contains(query) ||
                (v.licensePlate?.toLowerCase().contains(query) ?? false) ||
                (v.driverName?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // تصفية حسب الفلاتر
    if (_showActiveOnly) {
      filtered = filtered.where((v) => v.active).toList();
    }

    if (_onlyWithDriver) {
      filtered = filtered.where((v) => v.hasDriver).toList();
    }

    if (_onlyWithParking) {
      filtered = filtered.where((v) => v.hasParkingLocation).toList();
    }

    // الترتيب
    filtered.sort((a, b) {
      switch (_sortOption) {
        case VehicleSortOption.nameAsc:
          return a.name.compareTo(b.name);
        case VehicleSortOption.nameDesc:
          return b.name.compareTo(a.name);
        case VehicleSortOption.capacityAsc:
          return a.seatCapacity.compareTo(b.seatCapacity);
        case VehicleSortOption.capacityDesc:
          return b.seatCapacity.compareTo(a.seatCapacity);
        case VehicleSortOption.tripsAsc:
          return a.tripCount.compareTo(b.tripCount);
        case VehicleSortOption.tripsDesc:
          return b.tripCount.compareTo(a.tripCount);
      }
    });

    return filtered;
  }

  void _showFiltersDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) {
        bool localActiveOnly = _showActiveOnly;
        bool localWithDriver = _onlyWithDriver;
        bool localWithParking = _onlyWithParking;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'فلترة المركبات',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: localActiveOnly,
                    onChanged: (v) => setDialogState(() => localActiveOnly = v),
                    title: const Text('نشطة فقط', style: TextStyle(fontFamily: 'Cairo')),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    value: localWithDriver,
                    onChanged: (v) => setDialogState(() => localWithDriver = v),
                    title: const Text('مع سائق', style: TextStyle(fontFamily: 'Cairo')),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    value: localWithParking,
                    onChanged: (v) => setDialogState(() => localWithParking = v),
                    title: const Text('مع موقف', style: TextStyle(fontFamily: 'Cairo')),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      localActiveOnly = false;
                      localWithDriver = false;
                      localWithParking = false;
                    });
                  },
                  child: const Text('إعادة ضبط', style: TextStyle(fontFamily: 'Cairo')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showActiveOnly = localActiveOnly;
                      _onlyWithDriver = localWithDriver;
                      _onlyWithParking = localWithParking;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('تطبيق', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSortDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) {
        VehicleSortOption localSort = _sortOption;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'ترتيب المركبات',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<VehicleSortOption>(
                    value: VehicleSortOption.nameAsc,
                    groupValue: localSort,
                    onChanged: (v) => setDialogState(() => localSort = v!),
                    title: const Text('الاسم (أ-ي)', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  RadioListTile<VehicleSortOption>(
                    value: VehicleSortOption.nameDesc,
                    groupValue: localSort,
                    onChanged: (v) => setDialogState(() => localSort = v!),
                    title: const Text('الاسم (ي-أ)', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  RadioListTile<VehicleSortOption>(
                    value: VehicleSortOption.capacityAsc,
                    groupValue: localSort,
                    onChanged: (v) => setDialogState(() => localSort = v!),
                    title: const Text('السعة (صغير-كبير)', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  RadioListTile<VehicleSortOption>(
                    value: VehicleSortOption.capacityDesc,
                    groupValue: localSort,
                    onChanged: (v) => setDialogState(() => localSort = v!),
                    title: const Text('السعة (كبير-صغير)', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  RadioListTile<VehicleSortOption>(
                    value: VehicleSortOption.tripsAsc,
                    groupValue: localSort,
                    onChanged: (v) => setDialogState(() => localSort = v!),
                    title: const Text('الرحلات (قليل-كثير)', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  RadioListTile<VehicleSortOption>(
                    value: VehicleSortOption.tripsDesc,
                    groupValue: localSort,
                    onChanged: (v) => setDialogState(() => localSort = v!),
                    title: const Text('الرحلات (كثير-قليل)', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _sortOption = localSort);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('تطبيق', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(ShuttleVehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من حذف المركبة "${vehicle.name}"؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(vehicleActionsProvider.notifier)
                  .deleteVehicle(vehicle.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم حذف المركبة بنجاح' : 'فشل في حذف المركبة',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

/// تفاصيل المركبة
class _VehicleDetailsSheet extends StatelessWidget {
  final ShuttleVehicle vehicle;

  const _VehicleDetailsSheet({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (vehicle.licensePlate != null)
                            Text(
                              vehicle.licensePlate!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: vehicle.active
                                  ? Colors.green[50]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vehicle.active ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: vehicle.active
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // السعة
                _buildDetailRow(
                  Icons.event_seat_rounded,
                  'سعة المقاعد',
                  '${vehicle.seatCapacity} مقعد',
                ),

                // السائق
                if (vehicle.hasDriver) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.person_rounded,
                    'السائق الافتراضي',
                    vehicle.driverName ?? 'غير محدد',
                  ),
                ],

                // الملاحظات
                if (vehicle.note != null && vehicle.note!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.notes_rounded,
                    'ملاحظات',
                    vehicle.note!,
                  ),
                ],

                // عدد الرحلات
                if (vehicle.tripCount > 0) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.route_rounded,
                    'عدد الرحلات',
                    '${vehicle.tripCount} رحلة',
                  ),
                ],

                // موقع الموقف (Parking Location)
                if (vehicle.hasParkingLocation) ...[
                  const SizedBox(height: 16),
                  _buildParkingLocationSection(vehicle),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.local_parking_rounded,
                    'موقع الموقف',
                    'غير محدد',
                    isWarning: true,
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isWarning ? Colors.orange[500] : Colors.grey[500],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: isWarning ? Colors.orange[700] : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParkingLocationSection(ShuttleVehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.local_parking_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'موقع الموقف',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (vehicle.homeAddress != null &&
                      vehicle.homeAddress!.isNotEmpty)
                    Text(
                      vehicle.homeAddress!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${vehicle.homeLatitude!.toStringAsFixed(6)}, ${vehicle.homeLongitude!.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
