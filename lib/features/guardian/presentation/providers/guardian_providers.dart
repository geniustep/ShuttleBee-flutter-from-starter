import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../data/datasources/guardian_remote_data_source.dart';
import '../../domain/entities/guardian_info.dart';

/// Guardian Data Source Provider
final guardianDataSourceProvider = Provider<GuardianRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return GuardianRemoteDataSource(client);
});

/// معلومات ولي الأمر الحالي
final currentGuardianProvider =
    FutureProvider.autoDispose<GuardianInfo?>((ref) async {
  final dataSource = ref.watch(guardianDataSourceProvider);
  final authState = ref.watch(authStateProvider);

  if (dataSource == null) return null;

  final user = authState.asData?.value.user;
  if (user == null || user.partnerId == null) return null;

  return await dataSource.getGuardianInfo(user.partnerId!);
});

/// التابعين
final dependentsProvider =
    FutureProvider.autoDispose<List<DependentPassenger>>((ref) async {
  final dataSource = ref.watch(guardianDataSourceProvider);
  final authState = ref.watch(authStateProvider);

  if (dataSource == null) return [];

  final user = authState.asData?.value.user;
  if (user == null || user.partnerId == null) return [];

  return await dataSource.getDependents(user.partnerId!);
});

/// رحلات اليوم للتابعين
final todayDependentTripsProvider =
    FutureProvider.autoDispose<List<Trip>>((ref) async {
  final dataSource = ref.watch(guardianDataSourceProvider);
  final dependentsAsync = ref.watch(dependentsProvider);

  if (dataSource == null) return [];

  final dependents = dependentsAsync.asData?.value ?? [];
  if (dependents.isEmpty) return [];

  final dependentIds = dependents.map((d) => d.id).toList();
  return await dataSource.getTodayTripsForDependents(dependentIds);
});

/// رحلات تابع محدد
final dependentTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, int>((ref, dependentId) async {
  final dataSource = ref.watch(guardianDataSourceProvider);
  if (dataSource == null) return [];

  return await dataSource.getDependentTrips(dependentId);
});

/// الرحلة النشطة لتابع محدد
final activeTripForDependentProvider =
    FutureProvider.autoDispose.family<Trip?, int>((ref, dependentId) async {
  final dataSource = ref.watch(guardianDataSourceProvider);
  if (dataSource == null) return null;

  return await dataSource.getActiveTripForDependent(dependentId);
});

/// Guardian Actions Notifier
class GuardianActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  GuardianRemoteDataSource? get _dataSource =>
      ref.read(guardianDataSourceProvider);

  /// تسجيل غياب مسبق
  Future<bool> reportAbsence({
    required int dependentId,
    required DateTime date,
    String? reason,
  }) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    state = const AsyncValue.loading();

    try {
      final success = await dataSource.reportAbsence(
        dependentId: dependentId,
        date: date,
        reason: reason,
      );

      state = const AsyncValue.data(null);

      if (success) {
        ref.invalidate(todayDependentTripsProvider);
        ref.invalidate(dependentTripsProvider(dependentId));
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// تحديث معلومات التابع
  Future<bool> updateDependentInfo({
    required int dependentId,
    int? pickupStopId,
    int? dropoffStopId,
    String? notes,
  }) async {
    final dataSource = _dataSource;
    if (dataSource == null) return false;

    state = const AsyncValue.loading();

    try {
      final success = await dataSource.updateDependentInfo(
        dependentId: dependentId,
        pickupStopId: pickupStopId,
        dropoffStopId: dropoffStopId,
        notes: notes,
      );

      state = const AsyncValue.data(null);

      if (success) {
        ref.invalidate(dependentsProvider);
      }

      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Guardian Actions Provider
final guardianActionsProvider =
    NotifierProvider<GuardianActionsNotifier, AsyncValue<void>>(() {
  return GuardianActionsNotifier();
});

