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

  Future<void> updatePassenger({
    required int passengerId,
    String? name,
    String? phone,
    String? mobile,
    String? guardianPhone,
    String? guardianEmail,
    String? street,
    String? street2,
    String? city,
    String? zip,
    String? notes,
    double? latitude,
    double? longitude,
    bool? useGpsForPickup,
    bool? useGpsForDropoff,
    String? tripDirection,
    bool? autoNotification,
    bool? active,
  }) async {
    final values = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) values['name'] = name.trim();
    if (phone != null)
      values['phone'] = phone.trim().isEmpty ? false : phone.trim();
    if (mobile != null)
      values['mobile'] = mobile.trim().isEmpty ? false : mobile.trim();
    if (guardianPhone != null)
      values['guardian_phone'] =
          guardianPhone.trim().isEmpty ? false : guardianPhone.trim();
    if (guardianEmail != null)
      values['guardian_email'] =
          guardianEmail.trim().isEmpty ? false : guardianEmail.trim();
    if (street != null)
      values['street'] = street.trim().isEmpty ? false : street.trim();
    if (street2 != null)
      values['street2'] = street2.trim().isEmpty ? false : street2.trim();
    if (city != null)
      values['city'] = city.trim().isEmpty ? false : city.trim();
    if (zip != null) values['zip'] = zip.trim().isEmpty ? false : zip.trim();
    if (notes != null)
      values['shuttle_notes'] = notes.trim().isEmpty ? false : notes.trim();
    if (latitude != null) values['shuttle_latitude'] = latitude;
    if (longitude != null) values['shuttle_longitude'] = longitude;
    if (useGpsForPickup != null) values['use_gps_for_pickup'] = useGpsForPickup;
    if (useGpsForDropoff != null)
      values['use_gps_for_dropoff'] = useGpsForDropoff;
    if (tripDirection != null) values['shuttle_trip_direction'] = tripDirection;
    if (autoNotification != null)
      values['is_auto_notification'] = autoNotification;
    if (active != null) values['active'] = active;

    if (values.isEmpty) return;

    await _client.write(
      model: _partnerModel,
      ids: [passengerId],
      values: values,
    );
  }

  Future<void> deletePassenger(int passengerId) async {
    await _client.unlink(
      model: _partnerModel,
      ids: [passengerId],
    );
  }

  /// Update passenger temporary location
  Future<void> updateTemporaryLocation({
    required int passengerId,
    String? temporaryAddress,
    double? temporaryLatitude,
    double? temporaryLongitude,
    String? temporaryContactName,
    String? temporaryContactPhone,
  }) async {
    final values = <String, dynamic>{
      'temporary_address': temporaryAddress?.trim().isEmpty ?? true
          ? false
          : temporaryAddress?.trim(),
      'temporary_latitude': temporaryLatitude ?? false,
      'temporary_longitude': temporaryLongitude ?? false,
      'temporary_contact_name': temporaryContactName?.trim().isEmpty ?? true
          ? false
          : temporaryContactName?.trim(),
      'temporary_contact_phone': temporaryContactPhone?.trim().isEmpty ?? true
          ? false
          : temporaryContactPhone?.trim(),
    };

    await _client.write(
      model: _partnerModel,
      ids: [passengerId],
      values: values,
    );
  }

  /// Clear temporary location
  Future<void> clearTemporaryLocation(int passengerId) async {
    await _client.write(
      model: _partnerModel,
      ids: [passengerId],
      values: const {
        'temporary_address': false,
        'temporary_latitude': false,
        'temporary_longitude': false,
        'temporary_contact_name': false,
        'temporary_contact_phone': false,
      },
    );
  }

  /// Update guardian information
  Future<void> updateGuardianInfo({
    required int passengerId,
    bool? hasGuardian,
    String? fatherName,
    String? fatherPhone,
    String? motherName,
    String? motherPhone,
  }) async {
    final values = <String, dynamic>{};

    if (hasGuardian != null) values['has_guardian'] = hasGuardian;
    if (fatherName != null) {
      values['father_name'] =
          fatherName.trim().isEmpty ? false : fatherName.trim();
    }
    if (fatherPhone != null) {
      values['father_phone'] =
          fatherPhone.trim().isEmpty ? false : fatherPhone.trim();
    }
    if (motherName != null) {
      values['mother_name'] =
          motherName.trim().isEmpty ? false : motherName.trim();
    }
    if (motherPhone != null) {
      values['mother_phone'] =
          motherPhone.trim().isEmpty ? false : motherPhone.trim();
    }

    if (values.isEmpty) return;

    await _client.write(
      model: _partnerModel,
      ids: [passengerId],
      values: values,
    );
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
    // Guardian fields (new structure - replaced guardian_phone/guardian_email)
    'has_guardian',
    'father_name',
    'father_phone',
    'mother_name',
    'mother_phone',
    // Note: guardian_phone and guardian_email were removed from Odoo res.partner
    'shuttle_notes',
    // Temporary address fields
    'temporary_address',
    'temporary_latitude',
    'temporary_longitude',
    'temporary_contact_name',
    'temporary_contact_phone',
    'default_pickup_stop_id',
    'default_dropoff_stop_id',
  ];
}
