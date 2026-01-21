import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/services/dispatcher_initial_data_service.dart';
import '../providers/dispatcher_initial_load_provider.dart';

/// Widget لعرض حالة التحميل الأولي
///
/// يُستخدم في بداية صفحة الـ dispatcher لعرض تقدم التحميل
class DispatcherInitialLoadWidget extends ConsumerWidget {
  /// عرض كـ overlay أم كـ widget عادي
  final bool asOverlay;

  /// callback عند اكتمال التحميل
  final VoidCallback? onLoadComplete;

  /// عرض زر إعادة المحاولة
  final bool showRetryButton;

  const DispatcherInitialLoadWidget({
    super.key,
    this.asOverlay = false,
    this.onLoadComplete,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadState = ref.watch(dispatcherInitialLoadProvider);

    // استدعاء callback عند اكتمال التحميل
    ref.listen<DispatcherInitialLoadState>(
      dispatcherInitialLoadProvider,
      (previous, next) {
        if (next.isComplete && !next.hasError) {
          onLoadComplete?.call();
        }
      },
    );

    if (asOverlay) {
      return _buildOverlay(context, ref, loadState);
    }

    return _buildCard(context, ref, loadState);
  }

  Widget _buildOverlay(
    BuildContext context,
    WidgetRef ref,
    DispatcherInitialLoadState loadState,
  ) {
    if (loadState.isComplete && !loadState.hasError) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLoadingContent(context, ref, loadState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    DispatcherInitialLoadState loadState,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildLoadingContent(context, ref, loadState),
      ),
    );
  }

  Widget _buildLoadingContent(
    BuildContext context,
    WidgetRef ref,
    DispatcherInitialLoadState loadState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // العنوان
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loadState.isWindowsPlatform)
              const Icon(
                Icons.desktop_windows,
                color: AppColors.dispatcherPrimary,
                size: 24,
              ),
            const SizedBox(width: 8),
            Text(
              'تحميل البيانات الأولية',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dispatcherPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // مؤشر التقدم
        if (loadState.isLoading) ...[
          _buildProgressIndicator(loadState),
          const SizedBox(height: 16),
          Text(
            loadState.currentTask,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],

        // حالة الخطأ
        if (loadState.hasError) ...[
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            loadState.errorMessage ?? 'حدث خطأ أثناء التحميل',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
            textAlign: TextAlign.center,
          ),
          if (showRetryButton) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(dispatcherInitialLoadProvider.notifier)
                    .startInitialLoad(forceRefresh: true);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dispatcherPrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],

        // حالة النجاح
        if (loadState.isComplete && !loadState.hasError) ...[
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            loadState.result?.summary ?? 'تم تحميل البيانات بنجاح',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
            textAlign: TextAlign.center,
          ),
          if (loadState.result != null) ...[
            const SizedBox(height: 16),
            _buildResultStats(context, loadState.result!),
          ],
        ],

        // زر بدء التحميل (إذا لم يبدأ بعد)
        if (!loadState.isLoading &&
            !loadState.isComplete &&
            !loadState.hasError) ...[
          const Icon(
            Icons.cloud_download_outlined,
            color: AppColors.dispatcherPrimary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'اضغط لبدء تحميل البيانات',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(dispatcherInitialLoadProvider.notifier)
                  .startInitialLoad();
            },
            icon: const Icon(Icons.download),
            label: const Text('بدء التحميل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dispatcherPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressIndicator(DispatcherInitialLoadState loadState) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: loadState.progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.dispatcherPrimary,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(loadState.progress * 100).toInt()}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.dispatcherPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultStats(BuildContext context, InitialLoadResult result) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildStatChip(
          context,
          'الرحلات',
          result.tripsResult?.data?.length ?? 0,
          Icons.route,
          result.tripsResult?.isSuccess ?? false,
        ),
        _buildStatChip(
          context,
          'الركاب',
          result.passengersResult?.data?.length ?? 0,
          Icons.people,
          result.passengersResult?.isSuccess ?? false,
        ),
        _buildStatChip(
          context,
          'المركبات',
          result.vehiclesResult?.data?.length ?? 0,
          Icons.directions_bus,
          result.vehiclesResult?.isSuccess ?? false,
        ),
        _buildStatChip(
          context,
          'السائقين',
          result.driversResult?.data?.length ?? 0,
          Icons.person,
          result.driversResult?.isSuccess ?? false,
        ),
        _buildStatChip(
          context,
          'المرافقين',
          result.companionsResult?.data?.length ?? 0,
          Icons.person_outline,
          result.companionsResult?.isSuccess ?? false,
        ),
        _buildStatChip(
          context,
          'المجموعات',
          result.groupsResult?.data?.length ?? 0,
          Icons.group_work,
          result.groupsResult?.isSuccess ?? false,
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    bool isSuccess,
  ) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSuccess ? AppColors.success : AppColors.error,
      ),
      label: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          color: isSuccess ? Colors.grey[700] : AppColors.error,
        ),
      ),
      backgroundColor: isSuccess ? Colors.green[50] : Colors.red[50],
      side: BorderSide(
        color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
      ),
    );
  }
}

/// Widget مصغر لعرض حالة التحميل في الـ AppBar أو Header
class DispatcherLoadStatusIndicator extends ConsumerWidget {
  const DispatcherLoadStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadState = ref.watch(dispatcherInitialLoadProvider);

    if (loadState.isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(loadState.progress * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (loadState.hasError) {
      return IconButton(
        icon: const Icon(Icons.error_outline, color: Colors.orange),
        tooltip: 'خطأ في التحميل - اضغط لإعادة المحاولة',
        onPressed: () {
          ref
              .read(dispatcherInitialLoadProvider.notifier)
              .startInitialLoad(forceRefresh: true);
        },
      );
    }

    if (loadState.isComplete) {
      return const Icon(
        Icons.cloud_done,
        color: Colors.green,
        size: 20,
      );
    }

    return IconButton(
      icon: const Icon(Icons.cloud_download_outlined, color: Colors.white70),
      tooltip: 'تحميل البيانات',
      onPressed: () {
        ref.read(dispatcherInitialLoadProvider.notifier).startInitialLoad();
      },
    );
  }
}

/// Dialog لعرض تفاصيل البيانات المحملة
class DispatcherDataDetailsDialog extends ConsumerWidget {
  const DispatcherDataDetailsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(dispatcherCombinedDataProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.storage, color: AppColors.dispatcherPrimary),
          const SizedBox(width: 8),
          const Text('البيانات المحفوظة محلياً'),
        ],
      ),
      content: dataState.when(
        data: (data) => _buildDataContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('خطأ: $error'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        TextButton(
          onPressed: () async {
            await ref
                .read(dispatcherInitialLoadProvider.notifier)
                .clearCache();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم مسح البيانات المحفوظة')),
              );
            }
          },
          child: const Text(
            'مسح البيانات',
            style: TextStyle(color: AppColors.error),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref
                .read(dispatcherInitialLoadProvider.notifier)
                .startInitialLoad(forceRefresh: true);
          },
          child: const Text('تحديث الآن'),
        ),
      ],
    );
  }

  Widget _buildDataContent(BuildContext context, DispatcherDataState data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDataRow(context, 'الرحلات', data.tripsCount, Icons.route),
        _buildDataRow(context, 'الركاب', data.passengersCount, Icons.people),
        _buildDataRow(
            context, 'المركبات', data.vehiclesCount, Icons.directions_bus),
        _buildDataRow(context, 'السائقين', data.driversCount, Icons.person),
        _buildDataRow(
            context, 'المرافقين', data.companionsCount, Icons.person_outline),
        _buildDataRow(
            context, 'المجموعات', data.groupsCount, Icons.group_work),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.isLoaded ? Icons.check_circle : Icons.hourglass_empty,
              color: data.isLoaded ? AppColors.success : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              data.isLoaded ? 'البيانات محملة' : 'البيانات غير محملة',
              style: TextStyle(
                color: data.isLoaded ? AppColors.success : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    String label,
    int count,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.dispatcherPrimary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dispatcherPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

