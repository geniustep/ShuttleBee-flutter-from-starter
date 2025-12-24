import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/enums.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../models/trips_filter_model.dart';
import 'dispatcher_cached_providers.dart';

/// Notifier لإدارة حالة فلتر الرحلات
class TripsFilterNotifier extends Notifier<TripsFilterState> {
  @override
  TripsFilterState build() {
    return TripsFilterState();
  }

  /// تعيين نص البحث
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// مسح البحث
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// تبديل فلتر حالة الرحلة
  void toggleTripState(TripState tripState) {
    final newStates = Set<TripState>.from(state.tripStates);
    if (newStates.contains(tripState)) {
      newStates.remove(tripState);
    } else {
      newStates.add(tripState);
    }
    state = state.copyWith(tripStates: newStates);
  }

  /// تبديل فلتر نوع الرحلة
  void toggleTripType(TripType tripType) {
    final newTypes = Set<TripType>.from(state.tripTypes);
    if (newTypes.contains(tripType)) {
      newTypes.remove(tripType);
    } else {
      newTypes.add(tripType);
    }
    state = state.copyWith(tripTypes: newTypes);
  }

  /// تبديل فلتر "مع سائق فقط"
  void toggleWithDriver(bool value) {
    state = state.copyWith(onlyWithDriver: value);
  }

  /// تبديل فلتر "مع مركبة فقط"
  void toggleWithVehicle(bool value) {
    state = state.copyWith(onlyWithVehicle: value);
  }

  /// تبديل فلتر "مع GPS فقط"
  void toggleWithGps(bool value) {
    state = state.copyWith(onlyWithGps: value);
  }

  /// تبديل فلتر "مع مرافق فقط"
  void toggleWithCompanion(bool value) {
    state = state.copyWith(onlyWithCompanion: value);
  }

  /// تعيين خيار الترتيب
  void setSortOption(TripsSortOption option) {
    state = state.copyWith(sortBy: option);
  }

  /// تعيين التاريخ المحدد
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  /// تبديل فلتر التاريخ
  void toggleDateFilter(bool value) {
    state = state.copyWith(useDateFilter: value);
  }

  /// مسح كل الفلاتر (ما عدا التاريخ)
  void clearAllFilters() {
    state = state.copyWith(
      searchQuery: '',
      tripStates: {},
      tripTypes: {},
      onlyWithDriver: false,
      onlyWithVehicle: false,
      onlyWithGps: false,
      onlyWithCompanion: false,
      sortBy: TripsSortOption.defaultOrder,
      useDateFilter: true, // إعادة تفعيل فلتر التاريخ
    );
  }

  /// إزالة فلتر معين
  void removeFilter(ActiveTripFilter filter) {
    if (filter.filterType == 'all_trips') {
      toggleDateFilter(true);
    } else if (filter.filterType == 'search') {
      clearSearch();
    } else if (filter.filterType.startsWith('state_')) {
      final stateName = filter.filterType.split('_')[1];
      final state = TripState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => TripState.planned,
      );
      toggleTripState(state);
    } else if (filter.filterType.startsWith('type_')) {
      final typeName = filter.filterType.split('_')[1];
      final type = TripType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => TripType.pickup,
      );
      toggleTripType(type);
    } else if (filter.filterType == 'with_driver') {
      toggleWithDriver(false);
    } else if (filter.filterType == 'with_vehicle') {
      toggleWithVehicle(false);
    } else if (filter.filterType == 'with_gps') {
      toggleWithGps(false);
    } else if (filter.filterType == 'with_companion') {
      toggleWithCompanion(false);
    } else if (filter.filterType == 'sort') {
      setSortOption(TripsSortOption.defaultOrder);
    }
  }

  /// تطبيق الفلاتر على قائمة الرحلات
  List<Trip> applyFilters(List<Trip> trips) {
    var filtered = List<Trip>.from(trips);

    // فلتر الحالة
    if (state.tripStates.isNotEmpty) {
      filtered = filtered.where((t) => state.tripStates.contains(t.state)).toList();
    }

    // فلتر النوع
    if (state.tripTypes.isNotEmpty) {
      filtered = filtered.where((t) => state.tripTypes.contains(t.tripType)).toList();
    }

    // فلتر السائق
    if (state.onlyWithDriver) {
      filtered = filtered.where((t) => t.driverId != null).toList();
    }

    // فلتر المركبة
    if (state.onlyWithVehicle) {
      filtered = filtered.where((t) => t.vehicleId != null).toList();
    }

    // فلتر GPS
    if (state.onlyWithGps) {
      filtered = filtered.where((t) => t.currentLatitude != null && t.currentLongitude != null).toList();
    }

    // فلتر المرافق
    if (state.onlyWithCompanion) {
      filtered = filtered.where((t) => t.companionId != null).toList();
    }

    // فلتر البحث
    final query = state.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((t) {
        final name = t.name.toLowerCase();
        final driver = (t.driverName ?? '').toLowerCase();
        final companion = (t.companionName ?? '').toLowerCase();
        final vehicle = (t.vehicleName ?? '').toLowerCase();
        return name.contains(query) ||
            driver.contains(query) ||
            companion.contains(query) ||
            vehicle.contains(query);
      }).toList();
    }

    // الترتيب
    switch (state.sortBy) {
      case TripsSortOption.defaultOrder:
        // لا شيء - الترتيب الافتراضي
        break;
      case TripsSortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TripsSortOption.nameDesc:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case TripsSortOption.timeAsc:
        filtered.sort((a, b) {
          if (a.plannedStartTime == null && b.plannedStartTime == null) return 0;
          if (a.plannedStartTime == null) return 1;
          if (b.plannedStartTime == null) return -1;
          return a.plannedStartTime!.compareTo(b.plannedStartTime!);
        });
        break;
      case TripsSortOption.timeDesc:
        filtered.sort((a, b) {
          if (a.plannedStartTime == null && b.plannedStartTime == null) return 0;
          if (a.plannedStartTime == null) return -1;
          if (b.plannedStartTime == null) return 1;
          return b.plannedStartTime!.compareTo(a.plannedStartTime!);
        });
        break;
      case TripsSortOption.stateOrder:
        filtered.sort((a, b) => a.state.index.compareTo(b.state.index));
        break;
    }

    return filtered;
  }
}

/// Provider رئيسي لحالة الفلتر
final tripsFilterProvider = NotifierProvider<TripsFilterNotifier, TripsFilterState>(
  TripsFilterNotifier.new,
);

/// Provider للرحلات المفلترة
final filteredTripsProvider = Provider.family<List<Trip>, TripFilters>((ref, tripFilters) {
  final tripsAsync = ref.watch(dispatcherTripsProvider(tripFilters));
  final filterNotifier = ref.watch(tripsFilterProvider.notifier);

  // الاستماع للتغييرات في الفلتر
  ref.watch(tripsFilterProvider);

  return tripsAsync.when(
    data: (trips) => filterNotifier.applyFilters(trips),
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Provider لعدد نتائج الفلتر
final filterResultsCountProvider = Provider.family<int, TripFilters>((ref, tripFilters) {
  final filtered = ref.watch(filteredTripsProvider(tripFilters));
  return filtered.length;
});
