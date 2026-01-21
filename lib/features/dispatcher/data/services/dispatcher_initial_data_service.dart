import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/local_storage/domain/local_storage_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/entities/passenger_group.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../vehicles/domain/entities/shuttle_vehicle.dart';

/// خدمة التحميل الأولي للبيانات - Dispatcher Initial Data Service
///
/// تقوم بتحميل جميع البيانات الأساسية عند تسجيل الدخول للـ Dispatcher:
/// - الرحلات (Trips)
/// - الركاب (Passengers)
/// - المركبات (Vehicles)
/// - السائقين (Drivers)
/// - المرافقين (Companions)
/// - المجموعات (Groups)
///
/// تدعم:
/// - التخزين المحلي على Windows مع TTL أطول
/// - Offline-first architecture
/// - تحديث تلقائي في الخلفية
class DispatcherInitialDataService {
  final LocalStorageRepository _storage;
  final Ref _ref;

  // ════════════════════════════════════════════════════════════
  // Collection Names
  // ════════════════════════════════════════════════════════════
  
  static const String _tripsCollection = 'dispatcher_initial_trips';
  static const String _passengersCollection = 'dispatcher_initial_passengers';
  static const String _passengerProfilesCollection = 'dispatcher_initial_passenger_profiles';
  static const String _vehiclesCollection = 'dispatcher_initial_vehicles';
  static const String _driversCollection = 'dispatcher_initial_drivers';
  static const String _companionsCollection = 'dispatcher_initial_companions';
  static const String _groupsCollection = 'dispatcher_initial_groups';
  static const String _lastSyncKey = 'dispatcher_last_sync';
  static const String _syncStatusKey = 'dispatcher_sync_status';
  
  // 🆕 إصدار الكاش - يجب تحديثه عند تغيير هيكل البيانات
  // v2: إضافة pickup_stop_id, dropoff_stop_id للركاب
  // v3: إضافة ملفات تعريف الركاب (الإحداثيات)
  static const int _cacheVersion = 3;
  static const String _cacheVersionKey = 'dispatcher_cache_version';

  // ════════════════════════════════════════════════════════════
  // TTL Configuration (Windows-optimized)
  // ════════════════════════════════════════════════════════════
  
  // Windows يحصل على TTL أطول لأن الجهاز عادة يكون ثابت ومتصل
  // تحسين: زيادة TTL للبيانات الثابتة على Windows
  static Duration get _tripsTTL => 
      Platform.isWindows ? const Duration(hours: 8) : const Duration(hours: 2);
  
  static Duration get _passengersTTL => 
      Platform.isWindows ? const Duration(hours: 18) : const Duration(hours: 6);
  
  // تحسين: زيادة TTL للمركبات والسائقين والمرافقين على Windows (بيانات ثابتة)
  static Duration get _vehiclesTTL => 
      Platform.isWindows ? const Duration(days: 2) : const Duration(hours: 12);
  
  static Duration get _driversTTL => 
      Platform.isWindows ? const Duration(days: 2) : const Duration(hours: 12);
  
  static Duration get _companionsTTL => 
      Platform.isWindows ? const Duration(days: 2) : const Duration(hours: 12);
  
  static Duration get _groupsTTL => 
      Platform.isWindows ? const Duration(hours: 18) : const Duration(hours: 6);
  
  // 🆕 TTL لملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية)
  static Duration get _passengerProfilesTTL => 
      Platform.isWindows ? const Duration(hours: 24) : const Duration(hours: 12);

  // ════════════════════════════════════════════════════════════
  // Odoo Fields
  // ════════════════════════════════════════════════════════════
  
  static const List<String> _tripFields = [
    'id',
    'name',
    'display_name',
    'reference',
    'state',
    'trip_type',
    'date',
    'planned_start_time',
    'planned_arrival_time',
    'actual_start_time',
    'actual_arrival_time',
    'driver_id',
    'companion_id',
    'vehicle_id',
    'group_id',
    'total_passengers',
    'boarded_count',
    'absent_count',
    'dropped_count',
    'notes',
  ];

  static const List<String> _vehicleFields = [
    'id',
    'name',
    'fleet_vehicle_id',
    'license_plate',
    'seat_capacity',
    'driver_id',
    'color',
    'active',
    'note',
    'company_id',
  ];

  static const List<String> _groupFields = [
    'id',
    'name',
    'code',
    'driver_id',
    'companion_id',
    'vehicle_id',
    'total_seats',
    'trip_type',
    'color',
    'notes',
    'active',
    'company_id',
    'member_count',
  ];

  DispatcherInitialDataService(this._storage, this._ref);

  // ════════════════════════════════════════════════════════════
  // Main Initial Load Method
  // ════════════════════════════════════════════════════════════

  /// تحميل جميع البيانات الأولية
  /// 
  /// يتم استدعاء هذه الدالة عند تسجيل دخول الـ Dispatcher
  /// ترجع [InitialLoadResult] يحتوي على حالة التحميل والبيانات
  Future<InitialLoadResult> loadAllInitialData({
    bool forceRefresh = false,
    void Function(String, double)? onProgress,
  }) async {
    final result = InitialLoadResult();
    
    try {
      // تنظيف البيانات المنتهية الصلاحية عند بدء التطبيق
      onProgress?.call('جاري تنظيف البيانات...', 0.0);
      await cleanupExpiredData();
      
      // 🆕 التحقق من إصدار الكاش - إذا كان قديماً، نمسحه ونعيد التحميل
      final cachedVersion = await _getCacheVersion();
      if (cachedVersion != _cacheVersion) {
        debugPrint('🔄 إصدار الكاش قديم ($cachedVersion → $_cacheVersion)، سيتم إعادة التحميل');
        await clearAllCache();
        forceRefresh = true;
      }
      
      // التحقق من آخر مزامنة
      if (!forceRefresh) {
        final shouldSync = await _shouldPerformSync();
        if (!shouldSync) {
          // البيانات محدثة - تحميل من الكاش
          onProgress?.call('جاري تحميل البيانات المحفوظة...', 0.1);
          return await _loadFromCache(onProgress);
        }
      }

      onProgress?.call('جاري تحميل الرحلات...', 0.1);
      result.tripsResult = await _loadTrips();

      onProgress?.call('جاري تحميل الركاب...', 0.2);
      result.passengersResult = await _loadPassengers();

      // 🆕 تحميل ملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية)
      onProgress?.call('جاري تحميل إحداثيات الركاب...', 0.35);
      result.passengerProfilesResult = await _loadPassengerProfiles();

      onProgress?.call('جاري تحميل المركبات...', 0.5);
      result.vehiclesResult = await _loadVehicles();

      onProgress?.call('جاري تحميل السائقين...', 0.6);
      result.driversResult = await _loadDrivers();

      onProgress?.call('جاري تحميل المرافقين...', 0.75);
      result.companionsResult = await _loadCompanions();

      onProgress?.call('جاري تحميل المجموعات...', 0.9);
      result.groupsResult = await _loadGroups();

      onProgress?.call('اكتمل التحميل!', 1.0);

      // حفظ وقت آخر مزامنة وإصدار الكاش
      await _updateLastSyncTime();
      await _saveCacheVersion();

      // بدء التحديث التلقائي للرحلات النشطة
      startActiveTripsAutoRefresh();

      result.isComplete = true;
      return result;
    } catch (e) {
      result.error = e.toString();
      result.isComplete = false;
      return result;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Individual Load Methods
  // ════════════════════════════════════════════════════════════

  /// تحميل الرحلات من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<Trip>>> _loadTrips() async {
    try {
      // محاولة التحميل من الكاش أولاً
      final cachedTrips = await getCachedTrips();
      if (cachedTrips.isNotEmpty) {
        // تحديث في الخلفية
        _refreshTripsInBackground();
        return DataLoadStatus.success(cachedTrips, fromCache: true);
      }

      // التحميل من السيرفر
      final trips = await _fetchTripsFromServer();
      
      // حفظ في الكاش
      await _cacheTrips(trips);
      
      return DataLoadStatus.success(trips);
    } catch (e) {
      // محاولة استرجاع من الكاش عند الفشل
      final cached = await getCachedTrips();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  /// تحميل الركاب من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<Map<String, dynamic>>>> _loadPassengers() async {
    try {
      final cachedPassengers = await getCachedPassengers();
      
      // 🔍 التحقق من أن الكاش يحتوي على الحقول المطلوبة (pickup_stop_id)
      // إذا كان الكاش قديماً بدون هذه الحقول، نعيد تحميل البيانات
      final isCacheValid = cachedPassengers.isNotEmpty &&
          cachedPassengers.first.containsKey('pickup_stop_id');
      
      if (isCacheValid) {
        debugPrint('🔍 _loadPassengers: استخدام الكاش (${cachedPassengers.length} راكب)');
        _refreshPassengersInBackground();
        return DataLoadStatus.success(cachedPassengers, fromCache: true);
      }
      
      // الكاش فارغ أو قديم - جلب من السيرفر
      if (cachedPassengers.isNotEmpty && !isCacheValid) {
        debugPrint('🔍 _loadPassengers: الكاش قديم، سيتم إعادة التحميل');
      }

      final passengers = await _fetchPassengersFromServer();
      await _cachePassengers(passengers);
      return DataLoadStatus.success(passengers);
    } catch (e) {
      final cached = await getCachedPassengers();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  /// 🆕 تحميل ملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية) من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<Map<String, dynamic>>>> _loadPassengerProfiles() async {
    try {
      final cachedProfiles = await getCachedPassengerProfiles();
      
      // 🔍 التحقق من أن الكاش يحتوي على الحقول المطلوبة
      final isCacheValid = cachedProfiles.isNotEmpty &&
          cachedProfiles.first.containsKey('shuttle_latitude');
      
      if (isCacheValid) {
        debugPrint('🔍 _loadPassengerProfiles: استخدام الكاش (${cachedProfiles.length} ملف تعريف)');
        _refreshPassengerProfilesInBackground();
        return DataLoadStatus.success(cachedProfiles, fromCache: true);
      }
      
      // الكاش فارغ أو قديم - جلب من السيرفر
      if (cachedProfiles.isNotEmpty && !isCacheValid) {
        debugPrint('🔍 _loadPassengerProfiles: الكاش قديم، سيتم إعادة التحميل');
      }

      final profiles = await _fetchPassengerProfilesFromServer();
      await _cachePassengerProfiles(profiles);
      debugPrint('🔍 _loadPassengerProfiles: تم تحميل ${profiles.length} ملف تعريف من السيرفر');
      return DataLoadStatus.success(profiles);
    } catch (e) {
      debugPrint('🔍 _loadPassengerProfiles: خطأ: $e');
      final cached = await getCachedPassengerProfiles();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  /// تحميل المركبات من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<ShuttleVehicle>>> _loadVehicles() async {
    try {
      final cachedVehicles = await getCachedVehicles();
      if (cachedVehicles.isNotEmpty) {
        _refreshVehiclesInBackground();
        return DataLoadStatus.success(cachedVehicles, fromCache: true);
      }

      final vehicles = await _fetchVehiclesFromServer();
      await _cacheVehicles(vehicles);
      return DataLoadStatus.success(vehicles);
    } catch (e) {
      final cached = await getCachedVehicles();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  /// تحميل السائقين من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<Map<String, dynamic>>>> _loadDrivers() async {
    try {
      final cachedDrivers = await getCachedDrivers();
      if (cachedDrivers.isNotEmpty) {
        _refreshDriversInBackground();
        return DataLoadStatus.success(cachedDrivers, fromCache: true);
      }

      final drivers = await _fetchDriversFromServer();
      await _cacheDrivers(drivers);
      return DataLoadStatus.success(drivers);
    } catch (e) {
      final cached = await getCachedDrivers();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  /// تحميل المرافقين من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<Map<String, dynamic>>>> _loadCompanions() async {
    try {
      final cachedCompanions = await getCachedCompanions();
      if (cachedCompanions.isNotEmpty) {
        _refreshCompanionsInBackground();
        return DataLoadStatus.success(cachedCompanions, fromCache: true);
      }

      final companions = await _fetchCompanionsFromServer();
      await _cacheCompanions(companions);
      return DataLoadStatus.success(companions);
    } catch (e) {
      final cached = await getCachedCompanions();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  /// تحميل المجموعات من السيرفر وحفظها محلياً
  Future<DataLoadStatus<List<PassengerGroup>>> _loadGroups() async {
    try {
      final cachedGroups = await getCachedGroups();
      if (cachedGroups.isNotEmpty) {
        _refreshGroupsInBackground();
        return DataLoadStatus.success(cachedGroups, fromCache: true);
      }

      final groups = await _fetchGroupsFromServer();
      await _cacheGroups(groups);
      return DataLoadStatus.success(groups);
    } catch (e) {
      final cached = await getCachedGroups();
      if (cached.isNotEmpty) {
        return DataLoadStatus.partial(cached, error: e.toString());
      }
      return DataLoadStatus.failed(e.toString());
    }
  }

  // ════════════════════════════════════════════════════════════
  // Server Fetch Methods
  // ════════════════════════════════════════════════════════════

  Future<List<Trip>> _fetchTripsFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    // جلب رحلات اليوم والأيام القادمة
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final result = await client.searchRead(
      model: 'shuttle.trip',
      domain: [
        ['planned_start_time', '>=', today.toIso8601String()],
        ['planned_start_time', '<=', nextWeek.toIso8601String()],
      ],
      fields: _tripFields,
      limit: 500,
      order: 'planned_start_time asc',
    );

    return result.map((json) => Trip.fromOdoo(json)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPassengersFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    try {
      // 🎯 جلب بيانات shuttle.passenger.group.line مع كل الحقول المطلوبة
      // بما في ذلك المحطات (pickup_stop_id, dropoff_stop_id)
      final result = await client.searchRead(
        model: 'shuttle.passenger.group.line',
        domain: [],
        fields: [
          'id',
          'passenger_id',
          'group_id',
          'seat_count',
          'sequence',
          'notes',
          // 🆕 حقول المحطات - مهمة للخريطة
          'pickup_stop_id',
          'dropoff_stop_id',
          'pickup_info_display',
          'dropoff_info_display',
          // 🆕 حقول الراكب (related fields)
          'passenger_phone',
          'passenger_mobile',
          'father_phone',
          'mother_phone',
          'guardian_phone',
          'create_date',
          'write_date',
        ],
        limit: 1000,
      );

      // 🔍 Debug: طباعة أول راكب للتحقق من البيانات
      if (result.isNotEmpty) {
        debugPrint('🔍 Initial Load - أول راكب: ${result.first}');
        debugPrint('🔍 Initial Load - pickup_stop_id: ${result.first['pickup_stop_id']}');
        debugPrint('🔍 Initial Load - dropoff_stop_id: ${result.first['dropoff_stop_id']}');
      }

      return result;
    } catch (e) {
      // في حالة أخطاء الاتصال (502, 503, 504)، نرمي استثناء محدد
      // لتجنب إعادة المحاولة المتكررة
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('502') ||
          errorMsg.contains('503') ||
          errorMsg.contains('504') ||
          errorMsg.contains('bad gateway') ||
          errorMsg.contains('unexpected response format')) {
        throw Exception('Server error (502): Unable to fetch passengers. Using cached data.');
      }
      // إعادة رمي الخطأ الأصلي للأخطاء الأخرى
      rethrow;
    }
  }

  /// 🆕 جلب ملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية) من السيرفر
  /// هذه البيانات من res.partner وتحتوي على:
  /// - الإحداثيات (shuttle_latitude, shuttle_longitude)
  /// - المحطات الافتراضية (default_pickup_stop_id, default_dropoff_stop_id)
  Future<List<Map<String, dynamic>>> _fetchPassengerProfilesFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    try {
      final result = await client.searchRead(
        model: 'res.partner',
        domain: [
          ['is_shuttle_passenger', '=', true],
          ['active', '=', true],
        ],
        fields: [
          'id',
          'name',
          'phone',
          'mobile',
          // الإحداثيات - مهمة جداً للخريطة
          'shuttle_latitude',
          'shuttle_longitude',
          // المحطات الافتراضية
          'default_pickup_stop_id',
          'default_dropoff_stop_id',
          // إعدادات GPS
          'use_gps_for_pickup',
          'use_gps_for_dropoff',
          // حقول ولي الأمر
          'has_guardian',
          'father_name',
          'father_phone',
          'mother_name',
          'mother_phone',
          // العنوان المؤقت
          'temporary_address',
          'temporary_latitude',
          'temporary_longitude',
          'temporary_contact_name',
          'temporary_contact_phone',
        ],
        limit: 1000,
      );

      return result;
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('502') ||
          errorMsg.contains('503') ||
          errorMsg.contains('504') ||
          errorMsg.contains('bad gateway') ||
          errorMsg.contains('unexpected response format')) {
        throw Exception('Server error (502): Unable to fetch passenger profiles. Using cached data.');
      }
      rethrow;
    }
  }

  Future<List<ShuttleVehicle>> _fetchVehiclesFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    final result = await client.searchRead(
      model: 'shuttle.vehicle',
      domain: [],
      fields: _vehicleFields,
      limit: 200,
    );

    return result.map((json) => ShuttleVehicle.fromOdoo(json)).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchDriversFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    final result = await client.searchRead(
      model: 'res.users',
      domain: [
        ['shuttle_role', '=', 'driver'],
      ],
      fields: ['id', 'name', 'email', 'login', 'shuttle_role', 'partner_id'],
      limit: 200,
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> _fetchCompanionsFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    final result = await client.searchRead(
      model: 'res.users',
      domain: [
        ['shuttle_role', '=', 'companion'],
      ],
      fields: ['id', 'name', 'email', 'login', 'shuttle_role', 'partner_id'],
      limit: 200,
    );

    return result;
  }

  Future<List<PassengerGroup>> _fetchGroupsFromServer() async {
    final client = _ref.read(bridgecoreClientProvider);
    if (client == null) throw Exception('BridgeCore client not initialized');

    final result = await client.searchRead(
      model: 'shuttle.passenger.group',
      domain: [],
      fields: _groupFields,
      limit: 200,
    );

    return result.map((json) => PassengerGroup.fromOdoo(json)).toList();
  }

  // ════════════════════════════════════════════════════════════
  // Cache Methods
  // ════════════════════════════════════════════════════════════

  Future<void> _cacheTrips(List<Trip> trips) async {
    final tripsJson = trips.map((t) => t.toJson()).toList();
    await _storage.saveCollection(
      collectionName: _tripsCollection,
      items: tripsJson,
      ttl: _tripsTTL,
    );
  }

  Future<List<Trip>> getCachedTrips() async {
    final result = await _storage.loadCollection(_tripsCollection);
    return result.fold(
      (_) => [],
      (items) => items.map((json) => Trip.fromJson(json)).toList(),
    );
  }

  Future<void> _cachePassengers(List<Map<String, dynamic>> passengers) async {
    await _storage.saveCollection(
      collectionName: _passengersCollection,
      items: passengers,
      ttl: _passengersTTL,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedPassengers() async {
    final result = await _storage.loadCollection(_passengersCollection);
    return result.fold((_) => [], (items) {
      // 🔍 Debug: طباعة أول راكب من الكاش للتحقق
      if (items.isNotEmpty) {
        debugPrint('🔍 Cached Passengers - أول راكب: ${items.first}');
        debugPrint('🔍 Cached Passengers - pickup_stop_id: ${items.first['pickup_stop_id']}');
        debugPrint('🔍 Cached Passengers - dropoff_stop_id: ${items.first['dropoff_stop_id']}');
      }
      return items;
    });
  }

  /// 🆕 حفظ ملفات تعريف الركاب في الكاش
  Future<void> _cachePassengerProfiles(List<Map<String, dynamic>> profiles) async {
    await _storage.saveCollection(
      collectionName: _passengerProfilesCollection,
      items: profiles,
      ttl: _passengerProfilesTTL,
    );
  }

  /// 🆕 جلب ملفات تعريف الركاب من الكاش
  Future<List<Map<String, dynamic>>> getCachedPassengerProfiles() async {
    final result = await _storage.loadCollection(_passengerProfilesCollection);
    return result.fold((_) => [], (items) {
      // 🔍 Debug: طباعة أول ملف تعريف من الكاش للتحقق
      if (items.isNotEmpty) {
        debugPrint('🔍 Cached Profiles - أول ملف تعريف: ${items.first}');
        debugPrint('🔍 Cached Profiles - shuttle_latitude: ${items.first['shuttle_latitude']}');
        debugPrint('🔍 Cached Profiles - shuttle_longitude: ${items.first['shuttle_longitude']}');
      } else {
        debugPrint('🔍 Cached Profiles - الكاش فارغ!');
      }
      return items;
    });
  }

  Future<void> _cacheVehicles(List<ShuttleVehicle> vehicles) async {
    final vehiclesJson = vehicles.map((v) => v.toJson()).toList();
    await _storage.saveCollection(
      collectionName: _vehiclesCollection,
      items: vehiclesJson,
      ttl: _vehiclesTTL,
    );
  }

  Future<List<ShuttleVehicle>> getCachedVehicles() async {
    final result = await _storage.loadCollection(_vehiclesCollection);
    return result.fold(
      (_) => [],
      (items) => items.map((json) => ShuttleVehicle.fromJson(json)).toList(),
    );
  }

  Future<void> _cacheDrivers(List<Map<String, dynamic>> drivers) async {
    await _storage.saveCollection(
      collectionName: _driversCollection,
      items: drivers,
      ttl: _driversTTL,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedDrivers() async {
    final result = await _storage.loadCollection(_driversCollection);
    return result.fold((_) => [], (items) => items);
  }

  Future<void> _cacheCompanions(List<Map<String, dynamic>> companions) async {
    await _storage.saveCollection(
      collectionName: _companionsCollection,
      items: companions,
      ttl: _companionsTTL,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedCompanions() async {
    final result = await _storage.loadCollection(_companionsCollection);
    return result.fold((_) => [], (items) => items);
  }

  Future<void> _cacheGroups(List<PassengerGroup> groups) async {
    final groupsJson = groups.map((g) => g.toJson()).toList();
    await _storage.saveCollection(
      collectionName: _groupsCollection,
      items: groupsJson,
      ttl: _groupsTTL,
    );
  }

  Future<List<PassengerGroup>> getCachedGroups() async {
    final result = await _storage.loadCollection(_groupsCollection);
    return result.fold(
      (_) => [],
      (items) => items.map((json) => PassengerGroup.fromJson(json)).toList(),
    );
  }

  // ════════════════════════════════════════════════════════════
  // Background Refresh Methods
  // ════════════════════════════════════════════════════════════

  // Timer للرحلات النشطة - تحديث كل 5 دقائق
  Timer? _activeTripsRefreshTimer;

  /// بدء التحديث التلقائي للرحلات النشطة
  void startActiveTripsAutoRefresh() {
    // إيقاف التايمر السابق إن وجد
    _activeTripsRefreshTimer?.cancel();
    
    // تحديث فوري بعد ثانيتين
    _refreshTripsInBackground();
    
    // ثم تحديث دوري كل 5 دقائق
    _activeTripsRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshTripsInBackground(),
    );
  }

  /// إيقاف التحديث التلقائي
  void stopActiveTripsAutoRefresh() {
    _activeTripsRefreshTimer?.cancel();
    _activeTripsRefreshTimer = null;
  }

  void _refreshTripsInBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final trips = await _fetchTripsFromServer();
        await _cacheTrips(trips);
      } catch (_) {
        // Silent fail for background refresh
      }
    });
  }

  void _refreshPassengersInBackground() {
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final passengers = await _fetchPassengersFromServer();
        await _cachePassengers(passengers);
      } catch (_) {}
    });
  }

  /// 🆕 تحديث ملفات تعريف الركاب في الخلفية
  void _refreshPassengerProfilesInBackground() {
    Future.delayed(const Duration(seconds: 4), () async {
      try {
        final profiles = await _fetchPassengerProfilesFromServer();
        await _cachePassengerProfiles(profiles);
      } catch (_) {}
    });
  }

  void _refreshVehiclesInBackground() {
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final vehicles = await _fetchVehiclesFromServer();
        await _cacheVehicles(vehicles);
      } catch (_) {}
    });
  }

  void _refreshDriversInBackground() {
    Future.delayed(const Duration(seconds: 6), () async {
      try {
        final drivers = await _fetchDriversFromServer();
        await _cacheDrivers(drivers);
      } catch (_) {}
    });
  }

  void _refreshCompanionsInBackground() {
    Future.delayed(const Duration(seconds: 7), () async {
      try {
        final companions = await _fetchCompanionsFromServer();
        await _cacheCompanions(companions);
      } catch (_) {}
    });
  }

  void _refreshGroupsInBackground() {
    Future.delayed(const Duration(seconds: 8), () async {
      try {
        final groups = await _fetchGroupsFromServer();
        await _cacheGroups(groups);
      } catch (_) {}
    });
  }

  // ════════════════════════════════════════════════════════════
  // Cache Version Management
  // ════════════════════════════════════════════════════════════

  /// جلب إصدار الكاش المحفوظ
  Future<int> _getCacheVersion() async {
    final result = await _storage.load(_cacheVersionKey);
    return result.fold(
      (_) => 0,
      (data) => data?['version'] as int? ?? 0,
    );
  }

  /// حفظ إصدار الكاش الحالي
  Future<void> _saveCacheVersion() async {
    await _storage.save(
      key: _cacheVersionKey,
      data: {'version': _cacheVersion},
      ttl: const Duration(days: 365), // لا ينتهي
    );
  }

  // ════════════════════════════════════════════════════════════
  // Sync Management
  // ════════════════════════════════════════════════════════════

  Future<bool> _shouldPerformSync() async {
    final result = await _storage.load(_lastSyncKey);
    return result.fold(
      (_) => true,
      (data) {
        if (data == null) return true;
        
        final lastSync = DateTime.tryParse(data['timestamp'] as String? ?? '');
        if (lastSync == null) return true;

        // Windows: sync كل 8 ساعات (محسّن)، Mobile: كل ساعتين
        final syncInterval = Platform.isWindows
            ? const Duration(hours: 8)
            : const Duration(hours: 2);

        return DateTime.now().difference(lastSync) > syncInterval;
      },
    );
  }

  Future<void> _updateLastSyncTime() async {
    await _storage.save(
      key: _lastSyncKey,
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.isWindows ? 'windows' : 'mobile',
      },
      ttl: const Duration(days: 7),
    );
  }

  Future<InitialLoadResult> _loadFromCache(
    void Function(String, double)? onProgress,
  ) async {
    final result = InitialLoadResult();

    onProgress?.call('جاري تحميل الرحلات...', 0.1);
    final trips = await getCachedTrips();
    result.tripsResult = trips.isNotEmpty
        ? DataLoadStatus.success(trips, fromCache: true)
        : DataLoadStatus.failed('لا توجد رحلات محفوظة');

    onProgress?.call('جاري تحميل الركاب...', 0.25);
    final passengers = await getCachedPassengers();
    // 🔍 التحقق من صحة الكاش (يجب أن يحتوي على pickup_stop_id)
    final isPassengersCacheValid = passengers.isNotEmpty &&
        passengers.first.containsKey('pickup_stop_id');
    if (isPassengersCacheValid) {
      result.passengersResult = DataLoadStatus.success(passengers, fromCache: true);
    } else {
      // الكاش قديم - يجب إعادة التحميل
      debugPrint('🔍 _loadFromCache: كاش الركاب قديم، سيتم إعادة التحميل');
      result.passengersResult = DataLoadStatus.failed('كاش الركاب قديم');
    }

    // 🆕 تحميل ملفات تعريف الركاب (الإحداثيات)
    onProgress?.call('جاري تحميل إحداثيات الركاب...', 0.4);
    final passengerProfiles = await getCachedPassengerProfiles();
    // 🔍 التحقق من صحة الكاش (يجب أن يحتوي على shuttle_latitude)
    final isProfilesCacheValid = passengerProfiles.isNotEmpty &&
        passengerProfiles.first.containsKey('shuttle_latitude');
    if (isProfilesCacheValid) {
      result.passengerProfilesResult = DataLoadStatus.success(passengerProfiles, fromCache: true);
    } else {
      debugPrint('🔍 _loadFromCache: كاش ملفات التعريف قديم، سيتم إعادة التحميل');
      result.passengerProfilesResult = DataLoadStatus.failed('كاش ملفات التعريف قديم');
    }

    onProgress?.call('جاري تحميل المركبات...', 0.5);
    final vehicles = await getCachedVehicles();
    result.vehiclesResult = vehicles.isNotEmpty
        ? DataLoadStatus.success(vehicles, fromCache: true)
        : DataLoadStatus.failed('لا توجد مركبات محفوظة');

    onProgress?.call('جاري تحميل السائقين...', 0.65);
    final drivers = await getCachedDrivers();
    result.driversResult = drivers.isNotEmpty
        ? DataLoadStatus.success(drivers, fromCache: true)
        : DataLoadStatus.failed('لا يوجد سائقين محفوظين');

    onProgress?.call('جاري تحميل المرافقين...', 0.8);
    final companions = await getCachedCompanions();
    result.companionsResult = companions.isNotEmpty
        ? DataLoadStatus.success(companions, fromCache: true)
        : DataLoadStatus.failed('لا يوجد مرافقين محفوظين');

    onProgress?.call('جاري تحميل المجموعات...', 0.9);
    final groups = await getCachedGroups();
    result.groupsResult = groups.isNotEmpty
        ? DataLoadStatus.success(groups, fromCache: true)
        : DataLoadStatus.failed('لا توجد مجموعات محفوظة');

    onProgress?.call('اكتمل التحميل!', 1.0);

    result.isComplete = true;
    result.fromCache = true;
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // Clear Cache
  // ════════════════════════════════════════════════════════════

  /// مسح جميع البيانات المحفوظة
  Future<Either<Failure, bool>> clearAllCache() async {
    try {
      // إيقاف التحديث التلقائي
      stopActiveTripsAutoRefresh();
      
      // تنظيف البيانات المنتهية الصلاحية أولاً
      await _storage.clearExpired();
      
      // حذف المجموعات
      await _storage.deleteCollection(_tripsCollection);
      await _storage.deleteCollection(_passengersCollection);
      await _storage.deleteCollection(_passengerProfilesCollection);
      await _storage.deleteCollection(_vehiclesCollection);
      await _storage.deleteCollection(_driversCollection);
      await _storage.deleteCollection(_companionsCollection);
      await _storage.deleteCollection(_groupsCollection);
      await _storage.delete(_lastSyncKey);
      await _storage.delete(_syncStatusKey);
      
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'فشل مسح البيانات: $e'));
    }
  }

  /// تنظيف البيانات المنتهية الصلاحية
  Future<Either<Failure, int>> cleanupExpiredData() async {
    try {
      final result = await _storage.clearExpired();
      return result.fold(
        (failure) => Left(failure),
        (count) => Right(count),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'فشل تنظيف البيانات: $e'));
    }
  }
}

// ════════════════════════════════════════════════════════════
// Data Models
// ════════════════════════════════════════════════════════════

/// نتيجة التحميل الأولي
class InitialLoadResult {
  bool isComplete = false;
  bool fromCache = false;
  String? error;

  DataLoadStatus<List<Trip>>? tripsResult;
  DataLoadStatus<List<Map<String, dynamic>>>? passengersResult;
  /// 🆕 ملفات تعريف الركاب (الإحداثيات والمحطات الافتراضية)
  DataLoadStatus<List<Map<String, dynamic>>>? passengerProfilesResult;
  DataLoadStatus<List<ShuttleVehicle>>? vehiclesResult;
  DataLoadStatus<List<Map<String, dynamic>>>? driversResult;
  DataLoadStatus<List<Map<String, dynamic>>>? companionsResult;
  DataLoadStatus<List<PassengerGroup>>? groupsResult;

  /// هل تم تحميل جميع البيانات بنجاح
  bool get isAllSuccess =>
      tripsResult?.isSuccess == true &&
      passengersResult?.isSuccess == true &&
      passengerProfilesResult?.isSuccess == true &&
      vehiclesResult?.isSuccess == true &&
      driversResult?.isSuccess == true &&
      companionsResult?.isSuccess == true &&
      groupsResult?.isSuccess == true;

  /// عدد البيانات التي فشل تحميلها
  int get failedCount {
    int count = 0;
    if (tripsResult?.isFailed == true) count++;
    if (passengersResult?.isFailed == true) count++;
    if (passengerProfilesResult?.isFailed == true) count++;
    if (vehiclesResult?.isFailed == true) count++;
    if (driversResult?.isFailed == true) count++;
    if (companionsResult?.isFailed == true) count++;
    if (groupsResult?.isFailed == true) count++;
    return count;
  }

  /// ملخص حالة التحميل
  String get summary {
    if (isAllSuccess) return 'تم تحميل جميع البيانات بنجاح';
    if (failedCount == 7) return 'فشل تحميل جميع البيانات';
    return 'تم تحميل ${7 - failedCount}/7 من البيانات';
  }
}

/// حالة تحميل البيانات
enum LoadStatus { success, partial, failed }

/// حالة تحميل نوع معين من البيانات
class DataLoadStatus<T> {
  final LoadStatus status;
  final T? data;
  final String? error;
  final bool fromCache;

  DataLoadStatus._({
    required this.status,
    this.data,
    this.error,
    this.fromCache = false,
  });

  factory DataLoadStatus.success(T data, {bool fromCache = false}) {
    return DataLoadStatus._(
      status: LoadStatus.success,
      data: data,
      fromCache: fromCache,
    );
  }

  factory DataLoadStatus.partial(T data, {required String error}) {
    return DataLoadStatus._(
      status: LoadStatus.partial,
      data: data,
      error: error,
      fromCache: true,
    );
  }

  factory DataLoadStatus.failed(String error) {
    return DataLoadStatus._(
      status: LoadStatus.failed,
      error: error,
    );
  }

  bool get isSuccess => status == LoadStatus.success;
  bool get isPartial => status == LoadStatus.partial;
  bool get isFailed => status == LoadStatus.failed;
  bool get hasData => data != null;
}

