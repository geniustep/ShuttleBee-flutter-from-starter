import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading/shimmer_loading.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(allVehiclesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'إدارة المركبات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_off_rounded,
            ),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
              });
            },
            tooltip: _showActiveOnly ? 'إظهار الكل' : 'النشطة فقط',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allVehiclesProvider),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Vehicles List
          Expanded(
            child: vehiclesAsync.when(
              data: (vehicles) => _buildVehiclesList(vehicles),
              loading: () => _buildLoadingState(),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ابحث عن مركبة...',
          hintStyle: const TextStyle(fontFamily: 'Cairo'),
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildVehiclesList(List<ShuttleVehicle> vehicles) {
    var filteredVehicles = vehicles;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredVehicles = filteredVehicles
          .where((v) =>
              v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (v.licensePlate
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    // Apply active filter
    if (_showActiveOnly) {
      filteredVehicles =
          filteredVehicles.where((v) => v.active == true).toList();
    }

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
        ref.invalidate(allVehiclesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = filteredVehicles[index];
          return _buildVehicleCard(vehicle, index);
        },
      ),
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
                  color:
                      isActive ? AppColors.success : AppColors.textSecondary,
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
                                : AppColors.textSecondary.withValues(alpha: 0.1),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return ShimmerCard(height: 110);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(fontFamily: 'Cairo'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(allVehiclesProvider),
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
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      size: 56,
                      color: Color(0xFF7B1FA2),
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
                _buildDetailRow('رقم اللوحة', vehicle.licensePlate ?? 'غير محدد'),
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
