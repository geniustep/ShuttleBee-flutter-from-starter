import '../../../../../core/bridgecore_integration/client/bridgecore_client.dart';
import '../../domain/entities/dispatcher_passenger_profile.dart';

/// Dispatcher Partner Data Source
///
/// Creates shuttle passengers on Odoo `res.partner`.
class DispatcherPartnerRemoteDataSource {
  final BridgecoreClient _client;

  static const String _partnerModel = 'res.partner';

  DispatcherPartnerRemoteDataSource(this._client);

  Future<int> createPassenger({
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
    final values = <String, dynamic>{
      'name': name,
      'is_shuttle_passenger': true,
      'is_auto_notification': autoNotification,
      'use_gps_for_pickup': useGpsForPickup,
      'use_gps_for_dropoff': useGpsForDropoff,
      'shuttle_trip_direction': tripDirection,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (mobile != null && mobile.trim().isNotEmpty) 'mobile': mobile.trim(),
      if (guardianPhone != null && guardianPhone.trim().isNotEmpty)
        'guardian_phone': guardianPhone.trim(),
      if (guardianEmail != null && guardianEmail.trim().isNotEmpty)
        'guardian_email': guardianEmail.trim(),
      if (street != null && street.trim().isNotEmpty) 'street': street.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (notes != null && notes.trim().isNotEmpty)
        'shuttle_notes': notes.trim(),
      if (latitude != null) 'shuttle_latitude': latitude,
      if (longitude != null) 'shuttle_longitude': longitude,
    };

    return _client.create(model: _partnerModel, values: values);
  }

  Future<DispatcherPassengerProfile?> getPassengerById(int passengerId) async {
    final result = await _client.searchRead(
      model: _partnerModel,
      domain: [
        ['id', '=', passengerId],
      ],
      fields: _passengerFields,
      limit: 1,
      offset: 0,
    );

    if (result.isEmpty) return null;
    return DispatcherPassengerProfile.fromOdoo(result.first);
  }

  static const List<String> _passengerFields = [
    'id',
    'name',
    'active',
    'phone',
    'mobile',
    'street',
    'street2',
    'city',
    'zip',
    // ShuttleBee extensions
    'is_shuttle_passenger',
    'is_auto_notification',
    'use_gps_for_pickup',
    'use_gps_for_dropoff',
    'shuttle_trip_direction',
    'shuttle_latitude',
    'shuttle_longitude',
    'guardian_phone',
    'guardian_email',
    'shuttle_notes',
    'default_pickup_stop_id',
    'default_dropoff_stop_id',
  ];
}
