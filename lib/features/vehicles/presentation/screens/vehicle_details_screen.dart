import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/shuttle_vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../widgets/vehicle_form_dialog.dart';
import '../../../dispatcher/presentation/providers/dispatcher_cached_providers.dart';
import '../../../../shared/widgets/common/desktop_sidebar_wrapper.dart';

/// صفحة تفاصيل المركبة - ShuttleBee
class VehicleDetailsScreen extends ConsumerStatefulWidget {
  final int vehicleId;

  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  ConsumerState<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    // استخدام dispatcherVehicleByIdProvider الذي يستخدم الكاش
    final vehicleAsync = ref.watch(dispatcherVehicleByIdProvider(widget.vehicleId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // الرجوع إلى صفحة قائمة المركبات
        context.go('/dispatcher/vehicles');
      },
      child: DesktopScaffoldWithSidebar(
        backgroundColor: const Color(0xFFF8FAFC),
        body: vehicleAsync.when(
          data: (vehicle) {
            if (vehicle == null) {
              return _buildNotFoundState(context);
            }
            return _buildContent(context, ref, vehicle);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildErrorState(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ShuttleVehicle vehicle,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        _buildAppBar(context, ref, vehicle),
        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Section
              _buildHeroSection(context, vehicle),
              const SizedBox(height: 16),
              // Quick Actions
              _buildQuickActions(context, ref, vehicle),
              const SizedBox(height: 24),
              // Details Sections
              _buildDetailsSections(context, ref, vehicle),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, ShuttleVehicle vehicle) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => _showEditDialog(context, vehicle),
          tooltip: 'تعديل',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showMoreActions(context, ref, vehicle),
          tooltip: 'المزيد',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          vehicle.name,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ShuttleVehicle vehicle) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: vehicle.active
                  ? AppColors.success.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  vehicle.active ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 16,
                  color: vehicle.active ? AppColors.success : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  vehicle.active ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: vehicle.active ? AppColors.success : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Key Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                Icons.confirmation_number_rounded,
                'رقم اللوحة',
                vehicle.licensePlate ?? 'غير محدد',
              ),
              _buildInfoItem(
                Icons.event_seat_rounded,
                'السعة',
                '${vehicle.seatCapacity} مقعد',
              ),
              if (vehicle.hasDriver)
                _buildInfoItem(
                  Icons.person_rounded,
                  'السائق',
                  vehicle.driverName ?? 'غير محدد',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    ShuttleVehicle vehicle,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            context,
            Icons.edit_rounded,
            'تعديل',
            AppColors.primary,
            () => _showEditDialog(context, vehicle),
          ),
          _buildActionButton(
            context,
            vehicle.active ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            vehicle.active ? 'إلغاء التفعيل' : 'تفعيل',
            Colors.orange,
            () => _toggleActive(context, ref, vehicle),
          ),
          _buildActionButton(
            context,
            Icons.delete_rounded,
            'حذف',
            AppColors.error,
            () => _confirmDelete(context, ref, vehicle),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSections(
    BuildContext context,
    WidgetRef ref,
    ShuttleVehicle vehicle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // معلومات أساسية
        _buildSection(
          context,
          'معلومات أساسية',
          Icons.info_rounded,
          [
            _buildDetailRow('اسم المركبة', vehicle.name),
            if (vehicle.licensePlate != null)
              _buildDetailRow('رقم اللوحة', vehicle.licensePlate!),
            _buildDetailRow('سعة المقاعد', '${vehicle.seatCapacity} مقعد'),
            if (vehicle.driverName != null)
              _buildDetailRow('السائق', vehicle.driverName!),
            if (vehicle.companyName != null)
              _buildDetailRow('الشركة', vehicle.companyName!),
          ],
        ),
        const SizedBox(height: 16),
        // موقع الموقف
        if (vehicle.hasParkingLocation || vehicle.homeAddress != null)
          _buildSection(
            context,
            'موقع الموقف',
            Icons.local_parking_rounded,
            [
              if (vehicle.homeAddress != null && vehicle.homeAddress!.isNotEmpty)
                _buildDetailRow('العنوان', vehicle.homeAddress!),
              if (vehicle.hasParkingLocation)
                _buildDetailRow(
                  'الإحداثيات',
                  '${vehicle.homeLatitude!.toStringAsFixed(6)}, ${vehicle.homeLongitude!.toStringAsFixed(6)}',
                ),
              TextButton.icon(
                onPressed: () {
                  // TODO: فتح الخريطة
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('سيتم إضافة عرض الموقع على الخريطة قريباً'),
                    ),
                  );
                },
                icon: const Icon(Icons.map_rounded),
                label: const Text(
                  'عرض على الخريطة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // إحصائيات
        _buildSection(
          context,
          'إحصائيات',
          Icons.analytics_rounded,
          [
            _buildDetailRow('عدد الرحلات', '${vehicle.tripCount} رحلة'),
            _buildDetailRow('الحالة', vehicle.active ? 'نشط' : 'غير نشط'),
          ],
        ),
        const SizedBox(height: 16),
        // ملاحظات
        if (vehicle.note != null && vehicle.note!.isNotEmpty)
          _buildSection(
            context,
            'ملاحظات',
            Icons.notes_rounded,
            [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  vehicle.note!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'المركبة غير موجودة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ في تحميل البيانات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(dispatcherVehicleByIdProvider(widget.vehicleId));
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ShuttleVehicle vehicle) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => VehicleFormDialog(vehicle: vehicle),
    ).then((success) {
      if (success == true && context.mounted) {
        // تحديث البيانات - سيتم تحديثها تلقائياً عبر provider
        // لا حاجة لإعادة تحميل الصفحة
      }
    });
  }

  void _showMoreActions(
    BuildContext context,
    WidgetRef ref,
    ShuttleVehicle vehicle,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              title: const Text('تحديث البيانات', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                ref.invalidate(dispatcherVehicleByIdProvider(widget.vehicleId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث البيانات', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppColors.primary),
              title: const Text('مشاركة', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                // TODO: إضافة مشاركة
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم إضافة المشاركة قريباً', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: AppColors.primary),
              title: const Text('سجل الرحلات', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                // TODO: الانتقال إلى صفحة رحلات المركبة
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم إضافة صفحة رحلات المركبة قريباً', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    ShuttleVehicle vehicle,
  ) async {
    HapticFeedback.mediumImpact();
    final updatedVehicle = vehicle.copyWith(active: !vehicle.active);
    final result = await ref.read(vehicleActionsProvider.notifier).updateVehicle(updatedVehicle);

    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedVehicle.active ? 'تم تفعيل المركبة' : 'تم إلغاء تفعيل المركبة',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(dispatcherVehicleByIdProvider(widget.vehicleId));
        // تحديث قائمة المركبات أيضاً
        ref.invalidate(dispatcherVehiclesProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحديث المركبة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ShuttleVehicle vehicle) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من حذف المركبة "${vehicle.name}"؟\n\nلا يمكن التراجع عن هذه العملية.',
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
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف المركبة بنجاح', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  context.pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل في حذف المركبة', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
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

