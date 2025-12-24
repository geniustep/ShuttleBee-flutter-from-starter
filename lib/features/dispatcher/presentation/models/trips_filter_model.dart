import 'package:flutter/material.dart';
import '../../../../core/enums/enums.dart';

/// خيارات الترتيب المتاحة للرحلات
enum TripsSortOption {
  defaultOrder,
  nameAsc,
  nameDesc,
  timeAsc,
  timeDesc,
  stateOrder,
}

/// فلتر نشط واحد
class ActiveTripFilter {
  final String label;
  final Color color;
  final String filterType;

  const ActiveTripFilter({
    required this.label,
    required this.color,
    required this.filterType,
  });
}

/// حالة الفلترة للرحلات
class TripsFilterState {
  final String searchQuery;
  final Set<TripState> tripStates;
  final Set<TripType> tripTypes;
  final bool onlyWithDriver;
  final bool onlyWithVehicle;
  final bool onlyWithGps;
  final bool onlyWithCompanion;
  final TripsSortOption sortBy;
  final DateTime selectedDate;
  final bool useDateFilter;

  TripsFilterState({
    this.searchQuery = '',
    this.tripStates = const {},
    this.tripTypes = const {},
    this.onlyWithDriver = false,
    this.onlyWithVehicle = false,
    this.onlyWithGps = false,
    this.onlyWithCompanion = false,
    this.sortBy = TripsSortOption.defaultOrder,
    DateTime? selectedDate,
    this.useDateFilter = true,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// نسخ مع تغييرات
  TripsFilterState copyWith({
    String? searchQuery,
    Set<TripState>? tripStates,
    Set<TripType>? tripTypes,
    bool? onlyWithDriver,
    bool? onlyWithVehicle,
    bool? onlyWithGps,
    bool? onlyWithCompanion,
    TripsSortOption? sortBy,
    DateTime? selectedDate,
    bool? useDateFilter,
  }) {
    return TripsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      tripStates: tripStates ?? this.tripStates,
      tripTypes: tripTypes ?? this.tripTypes,
      onlyWithDriver: onlyWithDriver ?? this.onlyWithDriver,
      onlyWithVehicle: onlyWithVehicle ?? this.onlyWithVehicle,
      onlyWithGps: onlyWithGps ?? this.onlyWithGps,
      onlyWithCompanion: onlyWithCompanion ?? this.onlyWithCompanion,
      sortBy: sortBy ?? this.sortBy,
      selectedDate: selectedDate ?? this.selectedDate,
      useDateFilter: useDateFilter ?? this.useDateFilter,
    );
  }

  /// هل توجد فلاتر نشطة؟
  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        tripStates.isNotEmpty ||
        tripTypes.isNotEmpty ||
        onlyWithDriver ||
        onlyWithVehicle ||
        onlyWithGps ||
        onlyWithCompanion ||
        sortBy != TripsSortOption.defaultOrder;
  }

  /// عدد الفلاتر النشطة
  int get activeFiltersCount {
    int count = 0;
    if (searchQuery.isNotEmpty) count++;
    count += tripStates.length;
    count += tripTypes.length;
    if (onlyWithDriver) count++;
    if (onlyWithVehicle) count++;
    if (onlyWithGps) count++;
    if (onlyWithCompanion) count++;
    if (sortBy != TripsSortOption.defaultOrder) count++;
    return count;
  }

  /// الحصول على قائمة الفلاتر النشطة
  List<ActiveTripFilter> getActiveFilters(BuildContext context) {
    final List<ActiveTripFilter> filters = [];

    if (!useDateFilter) {
      filters.add(ActiveTripFilter(
        label: 'كل الرحلات',
        color: const Color(0xFF9E9E9E),
        filterType: 'all_trips',
      ));
    }

    if (searchQuery.isNotEmpty) {
      filters.add(ActiveTripFilter(
        label: 'بحث: $searchQuery',
        color: const Color(0xFF2196F3),
        filterType: 'search',
      ));
    }

    for (final state in tripStates) {
      filters.add(ActiveTripFilter(
        label: _getStateLabel(state, context),
        color: state.color,
        filterType: 'state_${state.name}',
      ));
    }

    for (final type in tripTypes) {
      filters.add(ActiveTripFilter(
        label: _getTypeLabel(type, context),
        color: type == TripType.pickup
            ? const Color(0xFF9C27B0)
            : const Color(0xFF4CAF50),
        filterType: 'type_${type.name}',
      ));
    }

    if (onlyWithDriver) {
      filters.add(const ActiveTripFilter(
        label: 'مع سائق',
        color: Color(0xFF2196F3),
        filterType: 'with_driver',
      ));
    }

    if (onlyWithVehicle) {
      filters.add(const ActiveTripFilter(
        label: 'مع مركبة',
        color: Color(0xFFFF9800),
        filterType: 'with_vehicle',
      ));
    }

    if (onlyWithGps) {
      filters.add(const ActiveTripFilter(
        label: 'مع GPS',
        color: Color(0xFF4CAF50),
        filterType: 'with_gps',
      ));
    }

    if (onlyWithCompanion) {
      filters.add(const ActiveTripFilter(
        label: 'مع مرافق',
        color: Color(0xFF00BCD4),
        filterType: 'with_companion',
      ));
    }

    if (sortBy != TripsSortOption.defaultOrder) {
      filters.add(ActiveTripFilter(
        label: 'ترتيب: ${_getSortLabel(sortBy)}',
        color: const Color(0xFF607D8B),
        filterType: 'sort',
      ));
    }

    return filters;
  }

  String _getStateLabel(TripState state, BuildContext context) {
    return state.getLocalizedLabel(context);
  }

  String _getTypeLabel(TripType type, BuildContext context) {
    return type.getLabel('ar');
  }

  String _getSortLabel(TripsSortOption sort) {
    switch (sort) {
      case TripsSortOption.defaultOrder:
        return 'افتراضي';
      case TripsSortOption.nameAsc:
        return 'الاسم (أ-ي)';
      case TripsSortOption.nameDesc:
        return 'الاسم (ي-أ)';
      case TripsSortOption.timeAsc:
        return 'الوقت (الأقدم)';
      case TripsSortOption.timeDesc:
        return 'الوقت (الأحدث)';
      case TripsSortOption.stateOrder:
        return 'الحالة';
    }
  }
}
