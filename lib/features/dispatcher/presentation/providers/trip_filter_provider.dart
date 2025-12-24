import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/trip_line_status.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../models/trip_filter_model.dart';

/// Notifier لإدارة حالة الفلتر
class TripFilterNotifier extends Notifier<TripFilterState> {
  @override
  TripFilterState build() {
    return const TripFilterState();
  }

  /// تعيين نص البحث
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// مسح البحث
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// تبديل حالة راكب معينة
  void togglePassengerStatus(TripLineStatus status) {
    final statuses = Set<TripLineStatus>.from(state.passengerStatuses);
    if (statuses.contains(status)) {
      statuses.remove(status);
    } else {
      statuses.add(status);
    }
    state = state.copyWith(passengerStatuses: statuses);
  }

  /// تبديل موقع معين
  void toggleLocation(String location) {
    final locations = Set<String>.from(state.selectedLocations);
    if (locations.contains(location)) {
      locations.remove(location);
    } else {
      locations.add(location);
    }
    state = state.copyWith(selectedLocations: locations);
  }

  /// تبديل فلتر ولي الأمر
  void toggleHasGuardian(bool value) {
    state = state.copyWith(hasGuardianOnly: value);
  }

  /// تبديل فلتر رقم الهاتف
  void toggleHasPhone(bool value) {
    state = state.copyWith(hasPhoneOnly: value);
  }

  /// تبديل فلتر المجموعة
  void toggleGroupFilter(bool value) {
    state = state.copyWith(showGroupPassengersOnly: value);
  }

  /// تبديل فلتر الرحلات المعلقة
  void togglePendingTrips() {
    state = state.copyWith(
      showPendingTripsOnly: !state.showPendingTripsOnly,
      showActiveTripsOnly: false,
      showCompletedTripsOnly: false,
    );
  }

  /// تبديل فلتر الرحلات النشطة
  void toggleActiveTrips() {
    state = state.copyWith(
      showPendingTripsOnly: false,
      showActiveTripsOnly: !state.showActiveTripsOnly,
      showCompletedTripsOnly: false,
    );
  }

  /// تبديل فلتر الرحلات المكتملة
  void toggleCompletedTrips() {
    state = state.copyWith(
      showPendingTripsOnly: false,
      showActiveTripsOnly: false,
      showCompletedTripsOnly: !state.showCompletedTripsOnly,
    );
  }

  /// تعيين خيار الترتيب
  void setSortOption(SortOption option) {
    state = state.copyWith(sortBy: option);
  }

  /// إعادة تعيين جميع الفلاتر
  void resetFilters() {
    state = const TripFilterState();
  }

  /// مسح جميع الفلاتر
  void clearAllFilters() {
    state = const TripFilterState();
  }

  /// إزالة فلتر محدد
  void removeFilter(ActiveFilter filter) {
    if (filter.filterType == 'search') {
      clearSearch();
    } else if (filter.filterType.startsWith('status_')) {
      final statusName = filter.filterType.replaceFirst('status_', '');
      final status = TripLineStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => TripLineStatus.notStarted,
      );
      togglePassengerStatus(status);
    } else if (filter.filterType.startsWith('location_')) {
      final location = filter.filterType.replaceFirst('location_', '');
      toggleLocation(location);
    } else if (filter.filterType == 'guardian') {
      toggleHasGuardian(false);
    } else if (filter.filterType == 'phone') {
      toggleHasPhone(false);
    } else if (filter.filterType == 'sort') {
      setSortOption(SortOption.defaultOrder);
    }
  }

  /// تطبيق الفلاتر على قائمة الركاب
  List<TripLine> applyFilters(List<TripLine> passengers) {
    var filtered = passengers;

    // 1. فلتر البحث
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((passenger) {
        final name = passenger.passengerName?.toLowerCase() ?? '';
        final phone = passenger.passengerPhone ?? '';
        final location = passenger.pickupLocationName.toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            location.contains(query);
      }).toList();
    }

    // 2. فلتر الحالة
    if (state.passengerStatuses.isNotEmpty) {
      filtered = filtered
          .where(
            (passenger) => state.passengerStatuses.contains(passenger.status),
          )
          .toList();
    }

    // 3. فلتر الموقع
    if (state.selectedLocations.isNotEmpty) {
      filtered = filtered
          .where(
            (passenger) =>
                state.selectedLocations.contains(passenger.pickupLocationName),
          )
          .toList();
    }

    // 4. فلتر ولي الأمر
    if (state.hasGuardianOnly) {
      filtered = filtered.where((passenger) => passenger.hasGuardian).toList();
    }

    // 5. فلتر رقم الهاتف
    if (state.hasPhoneOnly) {
      filtered = filtered
          .where(
            (passenger) =>
                passenger.passengerPhone != null &&
                passenger.passengerPhone!.isNotEmpty,
          )
          .toList();
    }

    // 6. الترتيب
    switch (state.sortBy) {
      case SortOption.nameAsc:
        filtered.sort(
          (a, b) => (a.passengerName ?? '').compareTo(b.passengerName ?? ''),
        );
        break;
      case SortOption.nameDesc:
        filtered.sort(
          (a, b) => (b.passengerName ?? '').compareTo(a.passengerName ?? ''),
        );
        break;
      case SortOption.status:
        filtered.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
      case SortOption.location:
        filtered.sort(
          (a, b) => a.pickupLocationName.compareTo(b.pickupLocationName),
        );
        break;
      case SortOption.defaultOrder:
        // لا شيء - الترتيب الافتراضي
        break;
    }

    return filtered;
  }
}

/// Provider الرئيسي للفلتر
final tripFilterProvider =
    NotifierProvider<TripFilterNotifier, TripFilterState>(
      TripFilterNotifier.new,
    );

/// Provider للركاب المفلترين
final filteredPassengersProvider = Provider.family<List<TripLine>, int>((
  ref,
  tripId,
) {
  final trip = ref.watch(tripDetailProvider(tripId)).value;
  if (trip == null) return [];

  // استماع للتغييرات في حالة الفلتر
  ref.watch(tripFilterProvider); // Listen to filter changes
  final filterNotifier = ref.read(tripFilterProvider.notifier);

  return filterNotifier.applyFilters(trip.lines);
});

/// Provider لعدد نتائج الفلتر
final filterResultsCountProvider = Provider.family<int, int>((ref, tripId) {
  final filteredPassengers = ref.watch(filteredPassengersProvider(tripId));
  return filteredPassengers.length;
});
