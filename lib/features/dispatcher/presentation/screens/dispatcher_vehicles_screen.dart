import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../providers/dispatcher_cached_providers.dart';
import '../widgets/dispatcher_unified_header.dart';
import '../widgets/dispatcher_secondary_header.dart';
import '../widgets/dispatcher_footer.dart';
import '../widgets/dispatcher_action_fab.dart';

/// Dispatcher Vehicles Screen - شاشة إدارة المركبات للمرسل - ShuttleBee
class DispatcherVehiclesScreen extends ConsumerStatefulWidget {
  const DispatcherVehiclesScreen({super.key});

  @override
  ConsumerState<DispatcherVehiclesScreen> createState() =>
      _DispatcherVehiclesScreenState();
}

class _DispatcherVehiclesScreenState
    extends ConsumerState<DispatcherVehiclesScreen> {
  String _searchQuery = '';
  bool _showActiveOnly = false;
  bool _onlyWithDriver = false;
  bool _onlyWithParking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vehiclesAsync = ref.watch(dispatcherVehiclesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.dispatcherHome);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // === Unified Header ===
            _buildHeader(context, l10n, vehiclesAsync),

            // === شريط البحث والفلاتر (للموبايل فقط) ===
            _buildMobileSearchSection(context),

            // === Vehicles List ===
            Expanded(
              child: vehiclesAsync.when(
                data: (vehicles) => _buildVehiclesList(vehicles),
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),

        // === Footer (Tablet/Desktop only) - شريط معلومات فقط ===
        bottomNavigationBar: vehiclesAsync.maybeWhen(
          data: (vehicles) {
            final filteredCount = _getFilteredVehicles(vehicles).length;
            final activeCount = vehicles.where((v) => v.active).length;
            final withParking =
                vehicles.where((v) => v.hasParkingLocation).length;

            return DispatcherFooter(
              hideOnMobile: true,
              info: filteredCount != vehicles.length
                  ? 'عرض ${Formatters.formatSimple(filteredCount)} من ${Formatters.formatSimple(vehicles.length)} مركبة'
                  : '${l10n.total}: ${Formatters.formatSimple(vehicles.length)} ${l10n.vehicles}',
              stats: [
                DispatcherFooterStat(
                  icon: Icons.check_circle_rounded,
                  label: l10n.active,
                  value: Formatters.formatSimple(activeCount),
                  color: AppColors.success,
                ),
                DispatcherFooterStat(
                  icon: Icons.local_parking_rounded,
                  label: 'مع موقف',
                  value: Formatters.formatSimple(withParking),
                ),
              ],
              lastUpdated: DateTime.now(),
              syncStatus: DispatcherSyncStatus.synced,
            );
          },
          orElse: () => null,
        ),

        // === FAB (Mobile only) ===
        floatingActionButton: DispatcherActionFAB(
          actions: [
            DispatcherFabAction(
              icon: Icons.add_rounded,
              label: 'إضافة مركبة',
              isPrimary: true,
              onPressed: () {
                context.go('${RoutePaths.dispatcherHome}/vehicles/create');
              },
            ),
            if (_hasActiveFilters)
              DispatcherFabAction(
                icon: Icons.clear_all_rounded,
                label: 'مسح الفلاتر',
                onPressed: () {
                  setState(() {
                    _showActiveOnly = false;
                    _onlyWithDriver = false;
                    _onlyWithParking = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎯 HEADER BUILDER - يختلف حسب الجهاز
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<ShuttleVehicle>> vehiclesAsync,
  ) {
    return DispatcherUnifiedHeader(
      title: l10n.vehiclesManagement,
      subtitle: vehiclesAsync.maybeWhen(
        data: (vehicles) {
          final activeCount = vehicles.where((v) => v.active).length;
          return '${l10n.total}: ${Formatters.formatSimple(vehicles.length)} • ${l10n.active}: ${Formatters.formatSimple(activeCount)}';
        },
        orElse: () => null,
      ),
      searchHint: 'ابحث عن مركبة...',
      searchValue: _searchQuery,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      onSearchClear: () => setState(() => _searchQuery = ''),
      showSearch: !context.isMobile,
      onRefresh: () async {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.vehicles(userId: userId));
        }
        ref.invalidate(dispatcherVehiclesProvider);
      },
      isLoading: vehiclesAsync.isLoading,
      actions: [
        const RoleSwitcherButton(),
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: _hasActiveFilters ? AppColors.warning : Colors.white,
          ),
          onPressed: _openFiltersSheet,
          tooltip: 'فلترة متقدمة',
        ),
      ],
      primaryActions: [
        DispatcherHeaderAction(
          icon: Icons.add_rounded,
          label: 'إضافة مركبة',
          isPrimary: true,
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('${RoutePaths.dispatcherHome}/vehicles/create');
          },
        ),
        if (_hasActiveFilters)
          DispatcherHeaderAction(
            icon: Icons.clear_all_rounded,
            label: 'مسح الفلاتر',
            onPressed: () {
              setState(() {
                _showActiveOnly = false;
                _onlyWithDriver = false;
                _onlyWithParking = false;
              });
            },
          ),
      ],
      stats: vehiclesAsync.maybeWhen(
        data: (vehicles) => [
          DispatcherHeaderStat(
            icon: Icons.directions_bus_rounded,
            label: l10n.total,
            value: Formatters.formatSimple(vehicles.length),
          ),
          DispatcherHeaderStat(
            icon: Icons.check_circle_rounded,
            label: l10n.active,
            value:
                Formatters.formatSimple(vehicles.where((v) => v.active).length),
          ),
          DispatcherHeaderStat(
            icon: Icons.local_parking_rounded,
            label: 'مع موقف',
            value: Formatters.formatSimple(
                vehicles.where((v) => v.hasParkingLocation).length),
          ),
        ],
        orElse: () => [],
      ),
      filters: context.isMobile ? [] : _buildActiveFilterChips(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE SEARCH SECTION - شريط البحث والفلاتر للموبايل فقط
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileSearchSection(BuildContext context) {
    if (!context.isMobile) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حقل البحث
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              style: const TextStyle(fontSize: 14, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'ابحث عن مركبة...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
            ),
          ),

          // الفلاتر النشطة
          if (_buildActiveFilterChips().isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildActiveFilterChips()
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: f,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (_showActiveOnly) {
      chips.add(
        DispatcherFilterChip(
          label: 'نشطة فقط',
          isSelected: true,
          onTap: () => setState(() => _showActiveOnly = false),
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      );
    }

    if (_onlyWithDriver) {
      chips.add(
        DispatcherFilterChip(
          label: 'بسائق',
          isSelected: true,
          onTap: () => setState(() => _onlyWithDriver = false),
          icon: Icons.person_rounded,
          color: AppColors.primary,
        ),
      );
    }

    if (_onlyWithParking) {
      chips.add(
        DispatcherFilterChip(
          label: 'مع موقف',
          isSelected: true,
          onTap: () => setState(() => _onlyWithParking = false),
          icon: Icons.local_parking_rounded,
          color: AppColors.warning,
        ),
      );
    }

    return chips;
  }

  List<ShuttleVehicle> _getFilteredVehicles(List<ShuttleVehicle> vehicles) {
    var filteredVehicles = vehicles;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredVehicles = filteredVehicles
          .where(
            (v) =>
                v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (v.licensePlate
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    // Apply active filter
    if (_showActiveOnly) {
      filteredVehicles =
          filteredVehicles.where((v) => v.active == true).toList();
    }

    if (_onlyWithDriver) {
      filteredVehicles =
          filteredVehicles.where((v) => v.driverId != null).toList();
    }

    if (_onlyWithParking) {
      filteredVehicles = filteredVehicles
          .where(
            (v) =>
                v.hasParkingLocation ||
                (v.homeAddress?.trim().isNotEmpty ?? false),
          )
          .toList();
    }

    return filteredVehicles;
  }

  Widget _buildVehiclesList(List<ShuttleVehicle> vehicles) {
    final filteredVehicles = _getFilteredVehicles(vehicles);

    if (filteredVehicles.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_rounded,
        title: 'لا توجد مركبات',
        message: _searchQuery.isNotEmpty
            ? 'لم يتم العثور على نتائج للبحث'
            : 'لا توجد مركبات مسجلة حالياً',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final cache = ref.read(dispatcherCacheDataSourceProvider);
        final userId = ref.read(authStateProvider).asData?.value.user?.id ?? 0;
        if (userId != 0) {
          await cache.delete(DispatcherCacheKeys.vehicles(userId: userId));
        }
        ref.invalidate(dispatcherVehiclesProvider);
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          context.isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
        ),
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = filteredVehicles[index];
          return _buildVehicleCard(vehicle, index);
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _showActiveOnly || _onlyWithDriver || _onlyWithParking;

  Future<void> _openFiltersSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool localActiveOnly = _showActiveOnly;
        bool localWithDriver = _onlyWithDriver;
        bool localWithParking = _onlyWithParking;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Container(
              margin: const EdgeInsets.only(top: 100),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            color: AppColors.dispatcherPrimary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'فلترة المركبات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setLocal(() {
                                localActiveOnly = false;
                                localWithDriver = false;
                                localWithParking = false;
                              });
                            },
                            child: const Text(
                              'إعادة ضبط',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localActiveOnly,
                        onChanged: (v) => setLocal(() => localActiveOnly = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: const Text(
                          'نشطة فقط',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithDriver,
                        onChanged: (v) => setLocal(() => localWithDriver = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: const Text(
                          'مرتبطة بسائق',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: localWithParking,
                        onChanged: (v) => setLocal(() => localWithParking = v),
                        activeThumbColor: AppColors.dispatcherPrimary,
                        title: const Text(
                          'لديها موقف محدد',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dispatcherPrimary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showActiveOnly = localActiveOnly;
                                  _onlyWithDriver = localWithDriver;
                                  _onlyWithParking = localWithParking;
                                });
                                Navigator.pop(ctx);
                              },
                              child: const Text(
                                'تطبيق',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVehicleCard(ShuttleVehicle vehicle, int index) {
    final isActive = vehicle.active == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showVehicleDetails(vehicle);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  size: 36,
                  color: isActive ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'نشط' : 'غير نشط',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildVehicleInfo(
                          Icons.credit_card_rounded,
                          vehicle.licensePlate ?? 'غير محدد',
                        ),
                        const SizedBox(width: 16),
                        _buildVehicleInfo(
                          Icons.event_seat_rounded,
                          '${vehicle.seatCapacity} مقعد',
                        ),
                      ],
                    ),
                    if (vehicle.driverId != null) ...[
                      const SizedBox(height: 8),
                      _buildVehicleInfo(
                        Icons.person_rounded,
                        'مرتبط بسائق',
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(
          begin: 0.05,
          end: 0,
          duration: 300.ms,
          delay: (index * 50).ms,
        );
  }

  Widget _buildVehicleInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            isMobile ? 96 : 16, // مساحة إضافية للـ FAB على الهاتف
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            return const ShimmerCard(height: 110);
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final cache = ref.read(dispatcherCacheDataSourceProvider);
              final userId =
                  ref.read(authStateProvider).asData?.value.user?.id ?? 0;
              if (userId != 0) {
                await cache
                    .delete(DispatcherCacheKeys.vehicles(userId: userId));
              }
              ref.invalidate(dispatcherVehiclesProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetails(ShuttleVehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      size: 56,
                      color: AppColors.dispatcherPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    vehicle.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: vehicle.active
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      vehicle.active ? 'نشط' : 'غير نشط',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: vehicle.active
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildDetailRow(
                  'رقم اللوحة',
                  vehicle.licensePlate ?? 'غير محدد',
                ),
                _buildDetailRow('السعة', '${vehicle.seatCapacity} مقعد'),
                _buildDetailRow('عدد الرحلات', '${vehicle.tripCount}'),
                if (vehicle.homeAddress != null &&
                    vehicle.homeAddress!.trim().isNotEmpty)
                  _buildDetailRow('الموقع الرئيسي', vehicle.homeAddress!),
                if ((vehicle.homeAddress == null ||
                        vehicle.homeAddress!.trim().isEmpty) &&
                    vehicle.hasParkingLocation)
                  _buildDetailRow(
                    'موقع الموقف',
                    '${vehicle.homeLatitude}, ${vehicle.homeLongitude}',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
