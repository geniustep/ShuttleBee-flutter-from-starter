import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trips/presentation/providers/trip_providers.dart';

/// Manager Reports Screen - شاشة التقارير - ShuttleBee
///
/// عرض وإنشاء تقارير مفصلة عن العمليات
class ManagerReportsScreen extends ConsumerStatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  ConsumerState<ManagerReportsScreen> createState() =>
      _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends ConsumerState<ManagerReportsScreen> {
  String _selectedReportType = 'daily';
  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(managerAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(managerAnalyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildContent(analytics),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.md),
          Text(
            error,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.md),
          ElevatedButton(
            onPressed: () => ref.invalidate(managerAnalyticsProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ManagerAnalytics analytics) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerAnalyticsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Configuration
            _buildReportConfiguration(),

            const SizedBox(height: AppDimensions.lg),

            // Quick Report Types
            const Text('أنواع التقارير المتاحة', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildReportTypes(),

            const SizedBox(height: AppDimensions.xl),

            // Recent Reports
            const Text('التقارير الأخيرة', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildRecentReports(),

            const SizedBox(height: AppDimensions.xl),

            // Summary Statistics
            const Text('ملخص الإحصائيات', style: AppTypography.h4),
            const SizedBox(height: AppDimensions.md),
            _buildSummaryStats(analytics),
          ],
        ),
      ),
    );
  }

  Widget _buildReportConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: AppColors.primary),
                SizedBox(width: AppDimensions.sm),
                Text('إعدادات التقرير', style: AppTypography.h5),
              ],
            ),
            const SizedBox(height: AppDimensions.md),

            // Report Type Selector
            const Text('نوع التقرير', style: AppTypography.bodySmall),
            const SizedBox(height: AppDimensions.xs),
            DropdownButtonFormField<String>(
              initialValue: _selectedReportType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xs,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('تقرير يومي')),
                DropdownMenuItem(value: 'weekly', child: Text('تقرير أسبوعي')),
                DropdownMenuItem(value: 'monthly', child: Text('تقرير شهري')),
                DropdownMenuItem(value: 'custom', child: Text('تقرير مخصص')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedReportType = value;
                  });
                }
              },
            ),

            const SizedBox(height: AppDimensions.md),

            // Date Selector
            const Text('التاريخ', style: AppTypography.bodySmall),
            const SizedBox(height: AppDimensions.xs),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      DateFormat('yyyy/MM/dd', 'ar').format(_selectedDate),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.md),

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.description),
                label: Text(_isGenerating ? 'جاري الإنشاء...' : 'إنشاء تقرير'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppDimensions.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypes() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.md,
      crossAxisSpacing: AppDimensions.md,
      childAspectRatio: 1.3,
      children: [
        _buildReportTypeCard(
          'التقرير اليومي',
          'عرض أداء اليوم',
          Icons.today,
          AppColors.primary,
          () => _quickGenerateReport('daily'),
        ),
        _buildReportTypeCard(
          'التقرير الأسبوعي',
          'ملخص الأسبوع',
          Icons.date_range,
          AppColors.success,
          () => _quickGenerateReport('weekly'),
        ),
        _buildReportTypeCard(
          'التقرير الشهري',
          'إحصائيات الشهر',
          Icons.calendar_month,
          AppColors.warning,
          () => _quickGenerateReport('monthly'),
        ),
        _buildReportTypeCard(
          'تقرير الأداء',
          'تحليل الأداء',
          Icons.trending_up,
          AppColors.error,
          () => _quickGenerateReport('performance'),
        ),
      ],
    );
  }

  Widget _buildReportTypeCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: AppDimensions.sm),
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReports() {
    // Sample data - in real app, this would come from a provider
    final recentReports = [
      {
        'title':
            'التقرير اليومي - ${DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now())}',
        'type': 'يومي',
        'date': DateTime.now(),
        'status': 'مكتمل',
        'icon': Icons.description,
        'color': AppColors.success,
      },
      {
        'title': 'التقرير الأسبوعي - الأسبوع 48',
        'type': 'أسبوعي',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'مكتمل',
        'icon': Icons.description,
        'color': AppColors.primary,
      },
      {
        'title': 'تقرير الأداء الشهري - نوفمبر',
        'type': 'شهري',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'status': 'مكتمل',
        'icon': Icons.description,
        'color': AppColors.warning,
      },
    ];

    return Column(
      children: recentReports.map((report) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.sm),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: (report['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                report['icon'] as IconData,
                color: report['color'] as Color,
              ),
            ),
            title: Text(
              report['title'] as String,
              style: AppTypography.bodyMedium,
            ),
            subtitle: Text(
              'النوع: ${report['type']} - ${DateFormat('yyyy/MM/dd HH:mm', 'ar').format(report['date'] as DateTime)}',
              style: AppTypography.caption,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report['status'] as String,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              _showReportPreview(report);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryStats(ManagerAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            _buildSummaryRow(
              'إجمالي الرحلات الشهرية',
              '${analytics.totalTripsThisMonth}',
              Icons.route,
              AppColors.primary,
            ),
            const Divider(),
            _buildSummaryRow(
              'الرحلات المنجزة',
              '${analytics.completedTripsThisMonth}',
              Icons.check_circle,
              AppColors.success,
            ),
            const Divider(),
            _buildSummaryRow(
              'معدل النجاح',
              '${analytics.completionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              AppColors.success,
            ),
            const Divider(),
            _buildSummaryRow(
              'إجمالي الركاب',
              '${analytics.totalPassengersTransported}',
              Icons.people,
              AppColors.primary,
            ),
            const Divider(),
            _buildSummaryRow(
              'المسافة الكلية',
              '${analytics.totalDistanceKm.toStringAsFixed(0)} كم',
              Icons.map,
              AppColors.warning,
            ),
            const Divider(),
            _buildSummaryRow(
              'تكلفة الوقود',
              '${analytics.estimatedFuelCost.toStringAsFixed(0)} ريال',
              Icons.local_gas_station,
              AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    // Simulate report generation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء التقرير ${_getReportTypeName()}'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'عرض',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to report view
            },
          ),
        ),
      );
    }
  }

  Future<void> _quickGenerateReport(String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري إنشاء ${_getReportTypeNameByType(type)}...'),
        backgroundColor: AppColors.primary,
      ),
    );

    // Simulate report generation
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء ${_getReportTypeNameByType(type)} بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showReportPreview(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('النوع: ${report['type']}'),
            const SizedBox(height: 8),
            Text(
              'التاريخ: ${DateFormat('yyyy/MM/dd HH:mm', 'ar').format(report['date'] as DateTime)}',
            ),
            const SizedBox(height: 8),
            Text('الحالة: ${report['status']}'),
            const SizedBox(height: 16),
            const Text(
                'هذا معاينة للتقرير. في التطبيق الحقيقي، سيتم عرض محتوى التقرير الكامل هنا.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('سيتم تصدير التقرير قريباً'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('تصدير PDF'),
          ),
        ],
      ),
    );
  }

  String _getReportTypeName() {
    switch (_selectedReportType) {
      case 'daily':
        return 'اليومي';
      case 'weekly':
        return 'الأسبوعي';
      case 'monthly':
        return 'الشهري';
      case 'custom':
        return 'المخصص';
      default:
        return '';
    }
  }

  String _getReportTypeNameByType(String type) {
    switch (type) {
      case 'daily':
        return 'التقرير اليومي';
      case 'weekly':
        return 'التقرير الأسبوعي';
      case 'monthly':
        return 'التقرير الشهري';
      case 'performance':
        return 'تقرير الأداء';
      default:
        return '';
    }
  }
}
