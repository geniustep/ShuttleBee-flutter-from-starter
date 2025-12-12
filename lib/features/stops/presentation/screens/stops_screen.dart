import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/shuttle_stop.dart';
import '../providers/stop_providers.dart';

/// شاشة نقاط التوقف - ShuttleBee
class StopsScreen extends ConsumerStatefulWidget {
  const StopsScreen({super.key});

  @override
  ConsumerState<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends ConsumerState<StopsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStopsList(null), // الكل
                _buildStopsList(StopType.pickup), // صعود
                _buildStopsList(StopType.dropoff), // نزول
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStopDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'إضافة نقطة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'نقاط التوقف',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.map_rounded),
          onPressed: () => _showMapView(),
          tooltip: 'عرض الخريطة',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.invalidate(allStopsProvider);
          },
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
          hintText: 'البحث عن نقطة توقف...',
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            color: Colors.grey[400],
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontFamily: 'Cairo'),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'الكل', icon: Icon(Icons.location_on_rounded, size: 20)),
          Tab(text: 'صعود', icon: Icon(Icons.arrow_upward_rounded, size: 20)),
          Tab(text: 'نزول', icon: Icon(Icons.arrow_downward_rounded, size: 20)),
        ],
      ),
    );
  }

  Widget _buildStopsList(StopType? filterType) {
    final stopsAsync = ref.watch(allStopsProvider);

    return stopsAsync.when(
      data: (stops) {
        var filteredStops = stops;

        // تصفية حسب النوع
        if (filterType != null) {
          filteredStops = stops
              .where((s) => s.stopType == filterType || s.stopType == StopType.both)
              .toList();
        }

        // تصفية حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredStops = filteredStops
              .where((s) =>
                  s.name.toLowerCase().contains(query) ||
                  (s.code?.toLowerCase().contains(query) ?? false) ||
                  (s.city?.toLowerCase().contains(query) ?? false))
              .toList();
        }

        if (filteredStops.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredStops.length,
          itemBuilder: (context, index) {
            return _buildStopCard(filteredStops[index], index);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allStopsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopCard(ShuttleStop stop, int index) {
    final typeColor = Color(stop.stopType.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showStopDetails(stop),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة النوع
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStopIcon(stop.stopType),
                  color: typeColor,
                  size: 24,
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
                        if (stop.code != null) ...[
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
                              stop.code!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            stop.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (stop.city != null || stop.street != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stop.fullAddress.isNotEmpty
                                  ? stop.fullAddress
                                  : 'لا يوجد عنوان',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            stop.stopType.arabicLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        if (stop.hasCoordinates) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.gps_fixed_rounded,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'GPS',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (stop.usageCount > 0) ...[
                          Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.usageCount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
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
                onPressed: () => _showStopActions(stop),
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
              Icons.location_off_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد نقاط توقف',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف نقاط توقف جديدة لتظهر هنا',
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

  IconData _getStopIcon(StopType type) {
    switch (type) {
      case StopType.pickup:
        return Icons.arrow_upward_rounded;
      case StopType.dropoff:
        return Icons.arrow_downward_rounded;
      case StopType.both:
        return Icons.swap_vert_rounded;
    }
  }

  void _showStopDetails(ShuttleStop stop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StopDetailsSheet(stop: stop),
    );
  }

  void _showStopActions(ShuttleStop stop) {
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
                _showEditStopDialog(stop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_rounded, color: Colors.green),
              title: const Text('عرض على الخريطة',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                _showOnMap(stop);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(stop);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStopDialog() {
    // TODO: Implement add stop dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة نموذج إنشاء نقطة توقف قريباً'),
      ),
    );
  }

  void _showEditStopDialog(ShuttleStop stop) {
    // TODO: Implement edit stop dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة نموذج تعديل نقطة توقف قريباً'),
      ),
    );
  }

  void _showMapView() {
    // TODO: Implement map view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة عرض الخريطة قريباً'),
      ),
    );
  }

  void _showOnMap(ShuttleStop stop) {
    if (!stop.hasCoordinates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نقطة التوقف لا تحتوي على إحداثيات GPS'),
        ),
      );
      return;
    }
    // TODO: Navigate to map with stop location
  }

  void _confirmDelete(ShuttleStop stop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من حذف نقطة التوقف "${stop.name}"؟',
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
              final success =
                  await ref.read(stopActionsProvider.notifier).deleteStop(stop.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'تم حذف نقطة التوقف بنجاح' : 'فشل في حذف نقطة التوقف',
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

/// تفاصيل نقطة التوقف
class _StopDetailsSheet extends StatelessWidget {
  final ShuttleStop stop;

  const _StopDetailsSheet({required this.stop});

  @override
  Widget build(BuildContext context) {
    final typeColor = Color(stop.stopType.colorValue);

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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: typeColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stop.code != null)
                            Text(
                              stop.code!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                fontFamily: 'Cairo',
                              ),
                            ),
                          Text(
                            stop.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              stop.stopType.arabicLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
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

                // العنوان
                if (stop.fullAddress.isNotEmpty) ...[
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'العنوان',
                    stop.fullAddress,
                  ),
                  const SizedBox(height: 16),
                ],

                // الإحداثيات
                if (stop.hasCoordinates) ...[
                  _buildDetailRow(
                    Icons.gps_fixed_rounded,
                    'الإحداثيات',
                    '${stop.latitude!.toStringAsFixed(6)}, ${stop.longitude!.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 16),
                ],

                // عدد الاستخدام
                _buildDetailRow(
                  Icons.people_outline_rounded,
                  'عدد الاستخدام',
                  '${stop.usageCount} مرة',
                ),

                if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.notes_rounded,
                    'ملاحظات',
                    stop.notes!,
                  ),
                ],

                const SizedBox(height: 24),

                // أزرار الإجراءات
                if (stop.hasCoordinates)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Open in maps
                      },
                      icon: const Icon(Icons.map_rounded),
                      label: const Text(
                        'فتح في الخرائط',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

