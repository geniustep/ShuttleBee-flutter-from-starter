import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/role_switcher_widget.dart';
import 'dispatcher_app_bar.dart';
import 'dispatcher_secondary_header.dart';
import 'dispatcher_footer.dart';

/// Example of using the unified Dispatcher layout components
///
/// مثال شامل لاستخدام مكونات التخطيط الموحدة للمنسق:
/// - DispatcherAppBar: هايدر رئيسي مع gradient
/// - DispatcherSecondaryHeader: هايدر ثانوي للبحث والفلاتر
/// - DispatcherFooter: فوتر موحد مع إجراءات وحالة المزامنة
///
/// ## استخدام في صفحاتك:
///
/// ```dart
/// Scaffold(
///   backgroundColor: const Color(0xFFF8FAFC),
///   appBar: DispatcherAppBar(
///     title: 'إدارة المجموعات',
///     subtitle: 'إجمالي: 25 • نشطة: 20',
///     actions: [
///       const RoleSwitcherButton(),
///       IconButton(
///         icon: const Icon(Icons.refresh_rounded),
///         onPressed: _onRefresh,
///       ),
///     ],
///   ),
///   body: Column(
///     children: [
///       DispatcherSecondaryHeader(
///         searchHint: 'ابحث عن مجموعة...',
///         searchValue: _searchQuery,
///         onSearchChanged: (value) => setState(() => _searchQuery = value),
///         filters: [
///           DispatcherFilterChip(
///             label: 'نشطة فقط',
///             isSelected: _showActiveOnly,
///             onTap: () => setState(() => _showActiveOnly = !_showActiveOnly),
///           ),
///         ],
///         stats: [
///           DispatcherStatChip(
///             icon: Icons.groups_rounded,
///             label: 'المجموعات',
///             value: '25',
///           ),
///         ],
///       ),
///       Expanded(child: _buildContent()),
///     ],
///   ),
///   bottomNavigationBar: DispatcherFooter(
///     info: 'عرض 20 من 25 مجموعة',
///     syncStatus: DispatcherSyncStatus.synced,
///     actions: [
///       DispatcherFooterAction(
///         icon: Icons.add_rounded,
///         label: 'إضافة جديد',
///         isPrimary: true,
///         onPressed: _onAdd,
///       ),
///     ],
///   ),
/// )
/// ```
class DispatcherLayoutExample extends StatefulWidget {
  const DispatcherLayoutExample({super.key});

  @override
  State<DispatcherLayoutExample> createState() =>
      _DispatcherLayoutExampleState();
}

class _DispatcherLayoutExampleState extends State<DispatcherLayoutExample> {
  String _searchQuery = '';
  bool _showActiveOnly = true;
  bool _showCompleted = false;
  bool _showPending = true;
  DispatcherSyncStatus _syncStatus = DispatcherSyncStatus.synced;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // === Primary Header ===
      appBar: DispatcherAppBar(
        title: 'إدارة الموارد',
        subtitle: 'إجمالي: 45 عنصر • نشطة: 32',
        actions: [
          const RoleSwitcherButton(),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Handle notifications
            },
            tooltip: 'الإشعارات',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _syncStatus = DispatcherSyncStatus.syncing;
              });
              // Simulate sync
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _syncStatus = DispatcherSyncStatus.synced;
                  });
                }
              });
            },
            tooltip: 'تحديث',
          ),
        ],
      ),

      body: Column(
        children: [
          // === Secondary Header ===
          DispatcherSecondaryHeader(
            searchHint: 'ابحث في العناصر...',
            searchValue: _searchQuery,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onSearchClear: () => setState(() => _searchQuery = ''),

            // Action buttons
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showFiltersBottomSheet();
                },
                tooltip: 'فلترة متقدمة',
                style: IconButton.styleFrom(
                  backgroundColor: _hasActiveFilters
                      ? AppColors.dispatcherPrimary
                      : Colors.grey.shade200,
                  foregroundColor:
                      _hasActiveFilters ? Colors.white : AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort_rounded),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Handle sorting
                },
                tooltip: 'ترتيب',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ],

            // Active filters
            filters: [
              if (_showActiveOnly)
                DispatcherFilterChip(
                  label: 'نشطة فقط',
                  isSelected: true,
                  onTap: () => setState(() => _showActiveOnly = false),
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              if (_showCompleted)
                DispatcherFilterChip(
                  label: 'مكتملة',
                  isSelected: true,
                  onTap: () => setState(() => _showCompleted = false),
                  icon: Icons.done_all_rounded,
                  color: AppColors.primary,
                ),
              if (_showPending)
                DispatcherFilterChip(
                  label: 'قيد الانتظار',
                  isSelected: true,
                  onTap: () => setState(() => _showPending = false),
                  icon: Icons.pending_rounded,
                  color: AppColors.warning,
                  badge: '12',
                ),
            ],

            // Stats chips
            stats: [
              DispatcherStatChip(
                icon: Icons.inventory_2_rounded,
                label: 'إجمالي',
                value: '45',
                color: AppColors.dispatcherPrimary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Show all items
                },
              ),
              DispatcherStatChip(
                icon: Icons.check_circle_rounded,
                label: 'نشطة',
                value: '32',
                color: AppColors.success,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Show active items
                },
              ),
              DispatcherStatChip(
                icon: Icons.pending_rounded,
                label: 'قيد الانتظار',
                value: '8',
                color: AppColors.warning,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Show pending items
                },
              ),
              DispatcherStatChip(
                icon: Icons.done_all_rounded,
                label: 'مكتملة',
                value: '5',
                color: AppColors.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Show completed items
                },
              ),
            ],
          ),

          // === Content ===
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),

      // === Footer ===
      bottomNavigationBar: DispatcherFooter(
        info: _searchQuery.isEmpty
            ? 'عرض جميع العناصر (45)'
            : 'عرض نتائج البحث (12 من 45)',
        syncStatus: _syncStatus,
        actions: [
          DispatcherFooterAction(
            icon: Icons.add_rounded,
            label: 'إضافة جديد',
            isPrimary: true,
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Handle add new
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('إضافة عنصر جديد'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          if (_hasActiveFilters)
            DispatcherFooterAction(
              icon: Icons.clear_all_rounded,
              label: 'مسح الفلاتر',
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showActiveOnly = false;
                  _showCompleted = false;
                  _showPending = false;
                });
              },
            ),
          DispatcherFooterAction(
            icon: Icons.file_download_rounded,
            label: 'تصدير',
            onPressed: () {
              HapticFeedback.lightImpact();
              // Handle export
            },
          ),
        ],
      ),

      // === FAB ===
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dispatcher_example_fab',
        onPressed: () {
          HapticFeedback.mediumImpact();
          // Handle quick action
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'إضافة سريع',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppColors.dispatcherPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  bool get _hasActiveFilters =>
      _showActiveOnly || _showCompleted || _showPending;

  Widget _buildContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.dispatcherPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: AppColors.dispatcherPrimary,
                size: 28,
              ),
            ),
            title: Text(
              'عنصر رقم ${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: Text(
              'وصف العنصر هنا...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                // Show options
              },
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              // Handle tap
            },
          ),
        );
      },
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(top: 100),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.dispatcherPrimary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'فلترة العناصر',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showActiveOnly = false;
                          _showCompleted = false;
                          _showPending = false;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'إعادة ضبط',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showActiveOnly,
                  onChanged: (v) => setState(() => _showActiveOnly = v),
                  activeColor: AppColors.dispatcherPrimary,
                  title: const Text(
                    'نشطة فقط',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showCompleted,
                  onChanged: (v) => setState(() => _showCompleted = v),
                  activeColor: AppColors.dispatcherPrimary,
                  title: const Text(
                    'مكتملة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showPending,
                  onChanged: (v) => setState(() => _showPending = v),
                  activeColor: AppColors.dispatcherPrimary,
                  title: const Text(
                    'قيد الانتظار',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                const SizedBox(height: 16),
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
                        onPressed: () => Navigator.pop(ctx),
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
      ),
    );
  }
}
