import 'package:bridgecore_flutter_starter/core/theme/app_colors.dart';
import 'package:bridgecore_flutter_starter/core/theme/app_typography.dart';
import 'package:bridgecore_flutter_starter/core/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// Unified Header for Dispatcher screens
///
/// هيدر مختلف تماماً لكل جهاز:
/// - Mobile: AppBar بسيط ونظيف بدون تداخل
/// - Tablet: تخطيط متوسط مع Rail
/// - Desktop: Header كامل مع كل الإمكانيات
class DispatcherUnifiedHeader extends StatefulWidget {
  const DispatcherUnifiedHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.primaryActions = const [],
    this.stats = const [],
    this.filters = const [],
    this.searchHint,
    this.searchValue = '',
    this.onSearchChanged,
    this.onSearchClear,
    this.showSearch = true,
    this.bottom,
    this.onRefresh,
    this.isLoading = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<DispatcherHeaderAction> primaryActions;
  final List<DispatcherHeaderStat> stats;
  final List<Widget> filters;
  final String? searchHint;
  final String searchValue;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final bool showSearch;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onRefresh;
  final bool isLoading;

  @override
  State<DispatcherUnifiedHeader> createState() =>
      _DispatcherUnifiedHeaderState();
}

class _DispatcherUnifiedHeaderState extends State<DispatcherUnifiedHeader> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchValue;
  }

  @override
  void didUpdateWidget(DispatcherUnifiedHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchValue != widget.searchValue) {
      _searchController.text = widget.searchValue;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تصميم مختلف تماماً لكل جهاز
    if (context.isMobile) {
      return _buildMobileHeader(context);
    } else if (context.isTablet) {
      return _buildTabletHeader(context);
    } else {
      return _buildDesktopHeader(context);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE HEADER - بسيط ونظيف بدون أي تداخل
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === الصف الرئيسي: العنوان + الأزرار ===
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                children: [
                  // زر الرجوع
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                  // العنوان
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // زر التحديث
                  if (widget.onRefresh != null)
                    IconButton(
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 22),
                      color: Colors.white,
                      onPressed: widget.isLoading ? null : widget.onRefresh,
                    ),

                  // أزرار إضافية
                  ...widget.actions,
                ],
              ),
            ),

            // === TabBar فقط (إن وجد) ===
            if (widget.bottom != null) widget.bottom!,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 MOBILE SEARCH BAR - يظهر أسفل القائمة كـ Widget منفصل
  // ═══════════════════════════════════════════════════════════════════════════
  Widget buildMobileSearchBar(BuildContext context) {
    if (!widget.showSearch) return const SizedBox.shrink();

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
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
              decoration: InputDecoration(
                hintText: widget.searchHint ?? 'ابحث...',
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
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchClear?.call();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                widget.onSearchChanged?.call(value);
                setState(() {});
              },
              textInputAction: TextInputAction.search,
            ),
          ),

          // الفلاتر (إن وجدت)
          if (widget.filters.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.filters
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 📟 TABLET HEADER - تخطيط متوسط
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabletHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === الصف الأول: العنوان + الأزرار ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // زر الرجوع
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 22),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                  // العنوان والعنوان الفرعي
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontFamily: 'Cairo',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // الإحصائيات المختصرة
                  if (widget.stats.isNotEmpty) ...[
                    ...widget.stats
                        .take(3)
                        .map((stat) => _buildTabletStatChip(stat)),
                    const SizedBox(width: 8),
                  ],

                  // زر التحديث
                  if (widget.onRefresh != null)
                    IconButton(
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 24),
                      color: Colors.white,
                      onPressed: widget.isLoading ? null : widget.onRefresh,
                    ),

                  // أزرار إضافية
                  ...widget.actions,
                ],
              ),
            ),

            // === الصف الثاني: البحث + الإجراءات ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  // حقل البحث
                  if (widget.showSearch)
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                          decoration: InputDecoration(
                            hintText: widget.searchHint ?? 'ابحث...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.onSearchClear?.call();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            widget.onSearchChanged?.call(value);
                            setState(() {});
                          },
                        ),
                      ),
                    ),

                  // أزرار الإجراءات
                  if (widget.primaryActions.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ...widget.primaryActions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildActionButton(action, compact: true),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // === TabBar ===
            if (widget.bottom != null) widget.bottom!,
          ],
        ),
      ),
    );
  }

  Widget _buildTabletStatChip(DispatcherHeaderStat stat) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🖥️ DESKTOP HEADER - كامل مع كل الإمكانيات
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.dispatcherGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.dispatcherPrimary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === الصف الأول: العنوان + الإحصائيات + الأزرار ===
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  // زر الرجوع
                  if (Navigator.of(context).canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 24),
                      color: Colors.white,
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                  // العنوان والعنوان الفرعي
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.h5.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // الإحصائيات
                  if (widget.stats.isNotEmpty)
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.stats
                            .map((stat) => _buildDesktopStatChip(stat))
                            .toList(),
                      ),
                    ),

                  // زر التحديث + الأزرار
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onRefresh != null)
                        IconButton(
                          icon: widget.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 26),
                          color: Colors.white,
                          onPressed: widget.isLoading ? null : widget.onRefresh,
                        ),
                      ...widget.actions,
                    ],
                  ),
                ],
              ),
            ),

            // === الصف الثاني: البحث + الفلاتر + الإجراءات ===
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  // حقل البحث
                  if (widget.showSearch)
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Cairo',
                          ),
                          decoration: InputDecoration(
                            hintText: widget.searchHint ?? 'ابحث...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontFamily: 'Cairo',
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 22,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      widget.onSearchClear?.call();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            widget.onSearchChanged?.call(value);
                            setState(() {});
                          },
                        ),
                      ),
                    ),

                  const SizedBox(width: 16),

                  // الفلاتر
                  if (widget.filters.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: widget.filters
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: f,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),

                  // أزرار الإجراءات
                  if (widget.primaryActions.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.primaryActions
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _buildActionButton(action, compact: false),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),

            // === TabBar ===
            if (widget.bottom != null) widget.bottom!,
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatChip(DispatcherHeaderStat stat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                stat.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔘 ACTION BUTTON - زر الإجراء
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActionButton(DispatcherHeaderAction action,
      {bool compact = false}) {
    final bgColor =
        action.isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.2);
    final fgColor =
        action.isPrimary ? AppColors.dispatcherPrimary : Colors.white;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          action.onPressed?.call();
        },
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                action.icon,
                size: compact ? 18 : 20,
                color: fgColor,
              ),
              const SizedBox(width: 8),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header Action Button Data
class DispatcherHeaderAction {
  const DispatcherHeaderAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
}

/// Header Stat Chip Data
class DispatcherHeaderStat {
  const DispatcherHeaderStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}
