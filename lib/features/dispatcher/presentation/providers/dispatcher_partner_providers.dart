import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dispatcher_partner_remote_data_source.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';
import 'dispatcher_passenger_providers.dart';

final dispatcherPartnerDataSourceProvider =
    Provider<DispatcherPartnerRemoteDataSource?>((ref) {
  final client = ref.watch(bridgecoreClientProvider);
  if (client == null) return null;
  return DispatcherPartnerRemoteDataSource(client);
});

final dispatcherPassengerProfileProvider = FutureProvider.autoDispose
    .family<DispatcherPassengerProfile?, int>((ref, passengerId) async {
  final ds = ref.watch(dispatcherPartnerDataSourceProvider);
  if (ds == null) return null;
  return ds.getPassengerById(passengerId);
});

class DispatcherPartnerActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  DispatcherPartnerRemoteDataSource? get _ds =>
      ref.read(dispatcherPartnerDataSourceProvider);

  Future<int?> createPassenger({
    required String name,
    String? phone,
    String? mobile,
    String? guardianPhone,
    String? guardianEmail,
    String? street,
    String? city,
    String? notes,
    double? latitude,
    double? longitude,
    bool useGpsForPickup = true,
    bool useGpsForDropoff = true,
    String tripDirection = 'both',
    bool autoNotification = true,
  }) async {
    final ds = _ds;
    if (ds == null) return null;

    state = const AsyncValue.loading();
    try {
      final id = await ds.createPassenger(
        name: name,
        phone: phone,
        mobile: mobile,
        guardianPhone: guardianPhone,
        guardianEmail: guardianEmail,
        street: street,
        city: city,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        useGpsForPickup: useGpsForPickup,
        useGpsForDropoff: useGpsForDropoff,
        tripDirection: tripDirection,
        autoNotification: autoNotification,
      );

      // Ensure the backend created an unassigned line for the passenger.
      final passengerDs = ref.read(dispatcherPassengerDataSourceProvider);
      await passengerDs?.syncUnassignedPassengers();

      ref.invalidate(dispatcherUnassignedPassengersProvider);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final dispatcherPartnerActionsProvider =
    NotifierProvider<DispatcherPartnerActionsNotifier, AsyncValue<void>>(() {
  return DispatcherPartnerActionsNotifier();
});
