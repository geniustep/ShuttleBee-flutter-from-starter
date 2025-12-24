import 'package:flutter/material.dart';
import '../../../../core/enums/trip_line_status.dart';

/// خيارات الترتيب المتاحة للركاب
enum SortOption {
  defaultOrder,
  nameAsc,
  nameDesc,
  status,
  location,
}

/// فلتر نشط يظهر كـ Chip
class ActiveFilter {
  final String label;
  final Color color;
  final String filterType;

  ActiveFilter({
    required this.label,
    required this.color,
    required this.filterType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveFilter &&
          runtimeType == other.runtimeType &&
          filterType == filterType;

  @override
  int get hashCode => filterType.hashCode;
}

/// حالة الفلتر الكاملة
class TripFilterState {
  final String searchQuery;
  final Set<TripLineStatus> passengerStatuses;
  final Set<String> selectedLocations;
  final bool showGroupPassengersOnly;
  final bool hasGuardianOnly;
  final bool hasPhoneOnly;
  final bool showPendingTripsOnly;
  final bool showActiveTripsOnly;
  final bool showCompletedTripsOnly;
  final SortOption sortBy;
  final int resultsCount;

  const TripFilterState({
    this.searchQuery = '',
    this.passengerStatuses = const {},
    this.selectedLocations = const {},
    this.showGroupPassengersOnly = false,
    this.hasGuardianOnly = false,
    this.hasPhoneOnly = false,
    this.showPendingTripsOnly = false,
    this.showActiveTripsOnly = false,
    this.showCompletedTripsOnly = false,
    this.sortBy = SortOption.defaultOrder,
    this.resultsCount = 0,
  });

  /// نسخ مع تغييرات
  TripFilterState copyWith({
    String? searchQuery,
    Set<TripLineStatus>? passengerStatuses,
    Set<String>? selectedLocations,
    bool? showGroupPassengersOnly,
    bool? hasGuardianOnly,
    bool? hasPhoneOnly,
    bool? showPendingTripsOnly,
    bool? showActiveTripsOnly,
    bool? showCompletedTripsOnly,
    SortOption? sortBy,
    int? resultsCount,
  }) {
    return TripFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      passengerStatuses: passengerStatuses ?? this.passengerStatuses,
      selectedLocations: selectedLocations ?? this.selectedLocations,
      showGroupPassengersOnly:
          showGroupPassengersOnly ?? this.showGroupPassengersOnly,
      hasGuardianOnly: hasGuardianOnly ?? this.hasGuardianOnly,
      hasPhoneOnly: hasPhoneOnly ?? this.hasPhoneOnly,
      showPendingTripsOnly: showPendingTripsOnly ?? this.showPendingTripsOnly,
      showActiveTripsOnly: showActiveTripsOnly ?? this.showActiveTripsOnly,
      showCompletedTripsOnly:
          showCompletedTripsOnly ?? this.showCompletedTripsOnly,
      sortBy: sortBy ?? this.sortBy,
      resultsCount: resultsCount ?? this.resultsCount,
    );
  }

  /// هل يوجد فلاتر نشطة؟
  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      passengerStatuses.isNotEmpty ||
      selectedLocations.isNotEmpty ||
      showGroupPassengersOnly ||
      hasGuardianOnly ||
      hasPhoneOnly ||
      showPendingTripsOnly ||
      showActiveTripsOnly ||
      showCompletedTripsOnly ||
      sortBy != SortOption.defaultOrder;

  /// عدد الفلاتر النشطة
  int get activeFiltersCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    count += passengerStatuses.length;
    count += selectedLocations.length;
    if (showGroupPassengersOnly) count++;
    if (hasGuardianOnly) count++;
    if (hasPhoneOnly) count++;
    if (showPendingTripsOnly) count++;
    if (showActiveTripsOnly) count++;
    if (showCompletedTripsOnly) count++;
    if (sortBy != SortOption.defaultOrder) count++;
    return count;
  }

  /// الحصول على قائمة الفلاتر النشطة
  List<ActiveFilter> getActiveFilters(BuildContext context) {
    final List<ActiveFilter> filters = [];

    if (searchQuery.isNotEmpty) {
      filters.add(ActiveFilter(
        label: 'بحث: $searchQuery',
        color: const Color(0xFF2196F3),
        filterType: 'search',
      ));
    }

    for (final status in passengerStatuses) {
      filters.add(ActiveFilter(
        label: _getStatusLabel(status),
        color: _getStatusColor(status),
        filterType: 'status_${status.name}',
      ));
    }

    for (final location in selectedLocations) {
      filters.add(ActiveFilter(
        label: location,
        color: const Color(0xFF9C27B0),
        filterType: 'location_$location',
      ));
    }

    if (hasGuardianOnly) {
      filters.add(ActiveFilter(
        label: 'لديهم ولي أمر',
        color: const Color(0xFFFF9800),
        filterType: 'guardian',
      ));
    }

    if (hasPhoneOnly) {
      filters.add(ActiveFilter(
        label: 'لديهم رقم هاتف',
        color: const Color(0xFF00BCD4),
        filterType: 'phone',
      ));
    }

    if (sortBy != SortOption.defaultOrder) {
      filters.add(ActiveFilter(
        label: 'ترتيب: ${_getSortLabel(sortBy)}',
        color: const Color(0xFF607D8B),
        filterType: 'sort',
      ));
    }

    return filters;
  }

  String _getStatusLabel(TripLineStatus status) {
    return status.arabicLabel;
  }

  Color _getStatusColor(TripLineStatus status) {
    return status.color;
  }

  String _getSortLabel(SortOption sort) {
    switch (sort) {
      case SortOption.defaultOrder:
        return 'افتراضي';
      case SortOption.nameAsc:
        return 'الاسم (أ-ي)';
      case SortOption.nameDesc:
        return 'الاسم (ي-أ)';
      case SortOption.status:
        return 'الحالة';
      case SortOption.location:
        return 'الموقع';
    }
  }
}
