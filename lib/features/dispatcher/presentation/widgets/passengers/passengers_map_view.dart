import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/reusable_map_widget.dart';
import '../../../../../core/widgets/map_marker_types.dart';
import '../../../../../core/widgets/cross_platform_map.dart';
import '../../../../../core/widgets/map_download_dialog.dart';
import '../../../../../core/config/company_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/passenger_group_line.dart';
import '../../../domain/entities/dispatcher_passenger_profile.dart';
import '../../providers/dispatcher_passenger_providers.dart';
import '../../providers/dispatcher_partner_providers.dart';
import '../../providers/dispatcher_initial_load_provider.dart';
import '../../../../stops/presentation/providers/stop_providers.dart';
import '../../../../stops/domain/entities/shuttle_stop.dart';
import 'station_passengers_sheet.dart';

/// نتيجة بناء العلامات
class _PassengerMarkersResult {
  final List<MapMarkerData> markers;
  final Map<int, List<PassengerGroupLine>> stationPassengers;

  const _PassengerMarkersResult({
    required this.markers,
    required this.stationPassengers,
  });
}

/// 🗺️ Passengers Map View - عرض الركاب على الخريطة
class PassengersMapView extends ConsumerWidget {
  final List<PassengerGroupLine>? passengers;
  final PassengerGroupLine? selectedPassenger;
  final void Function(PassengerGroupLine)? onPassengerSelected;
  final bool showUnassignedOnly;

  const PassengersMapView({
    super.key,
    this.passengers,
    this.selectedPassenger,
    this.onPassengerSelected,
    this.showUnassignedOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الحصول على قائمة الركاب
    final passengersAsync = passengers != null
        ? AsyncValue.data(passengers!)
        : showUnassignedOnly
        ? ref.watch(dispatcherUnassignedPassengersProvider)
        : ref.watch(dispatcherAllPassengersProvider);

    return passengersAsync.when(
      data: (passengersList) {
        debugPrint('🗺️ تم استلام ${passengersList.length} راكب من Provider');

        if (passengersList.isEmpty) {
          return _buildEmptyState();
        }

        // إزالة التكرار من قائمة الركاب
        final uniquePassengers = <int, PassengerGroupLine>{};
        for (final passenger in passengersList) {
          if (!uniquePassengers.containsKey(passenger.passengerId)) {
            uniquePassengers[passenger.passengerId] = passenger;
          }
        }
        final deduplicatedPassengers = uniquePassengers.values.toList();
        debugPrint(
          '🗺️ بعد إزالة التكرار: ${deduplicatedPassengers.length} راكب فريد '
          '(تم حذف ${passengersList.length - deduplicatedPassengers.length} مكرر)',
        );

        final passengerIds = deduplicatedPassengers
            .map((p) => p.passengerId)
            .toList();

        // 🎯 جلب ملفات تعريف الركاب من البيانات المحملة مسبقاً
        // على Windows: نستخدم البيانات المحملة في التحميل الأولي
        // على Mobile: نستخدم الـ provider العادي
        AsyncValue<Map<int, DispatcherPassengerProfile>> profilesAsync;

        if (Platform.isWindows) {
          // استخدام البيانات المحملة مسبقاً من التحميل الأولي
          final preloadedProfilesAsync = ref.watch(
            dispatcherPreloadedPassengerProfilesProvider,
          );
          profilesAsync = preloadedProfilesAsync.when(
            data: (profilesList) {
              debugPrint(
                '🗺️ Windows: تم جلب ${profilesList.length} ملف تعريف محمّل مسبقاً',
              );
              // تحويل القائمة إلى Map
              final profilesMap = <int, DispatcherPassengerProfile>{};
              for (final json in profilesList) {
                final profile = DispatcherPassengerProfile.fromOdoo(json);
                profilesMap[profile.id] = profile;
              }
              // إذا كانت البيانات المحملة مسبقاً فارغة، نستخدم الـ batch provider
              if (profilesMap.isEmpty) {
                debugPrint(
                  '🗺️ Windows: البيانات المحملة مسبقاً فارغة، سيتم استخدام batch provider',
                );
              }
              return AsyncValue.data(profilesMap);
            },
            loading: () {
              debugPrint('🗺️ Windows: جاري تحميل ملفات التعريف...');
              return const AsyncValue.loading();
            },
            error: (e, st) {
              debugPrint('🗺️ Windows: خطأ في تحميل ملفات التعريف: $e');
              return AsyncValue.error(e, st);
            },
          );

          // إذا كانت البيانات المحملة مسبقاً فارغة، نستخدم الـ batch provider كـ fallback
          if (profilesAsync.hasValue && profilesAsync.value!.isEmpty) {
            debugPrint('🗺️ Windows: استخدام batch provider كـ fallback');
            profilesAsync = ref.watch(
              dispatcherPassengerProfilesBatchProvider(passengerIds),
            );
          }
        } else {
          // على Mobile: استخدام الـ provider الشامل أو الـ batch provider
          final allProfilesAsync = ref.watch(
            dispatcherAllPassengerProfilesProvider,
          );
          profilesAsync =
              allProfilesAsync.hasValue && allProfilesAsync.value!.isNotEmpty
              ? allProfilesAsync
              : ref.watch(
                  dispatcherPassengerProfilesBatchProvider(passengerIds),
                );
        }

        // جلب المحطات
        final stopsAsync = ref.watch(allStopsProvider);

        return Builder(
          builder: (ctx) {
            // 🔄 انتظار تحميل المحطات أيضاً
            return stopsAsync.when(
              data: (stops) {
                debugPrint('🗺️ تم تحميل ${stops.length} محطة');
                return profilesAsync.when(
                  data: (profiles) {
                    final result = _buildMarkersFromProfiles(
                      ctx,
                      deduplicatedPassengers,
                      profiles,
                      stops,
                    );

                    if (result.markers.isEmpty) {
                      return _buildNoLocationState();
                    }

                    final centerLocation = _calculateCenter(result.markers);

                    return ReusableMapWidget(
                      initialLocation: centerLocation,
                      initialZoom: 12.0,
                      markers: result.markers,
                      showMyLocation: true,
                      showMyLocationButton: true,
                      showZoomControls: true,
                      showTraffic: false,
                      enableViewportCulling: true,
                      enableClustering:
                          false, // تعطيل التجميع لأننا نجمّع يدوياً
                      clusteringThreshold: 30,
                      onMarkerTap: (markerId) {
                        final passengerId = int.tryParse(
                          markerId.replaceFirst('passenger_', ''),
                        );
                        if (passengerId != null) {
                          final passenger = passengersList.firstWhere(
                            (p) => p.passengerId == passengerId,
                            orElse: () => passengersList.first,
                          );
                          onPassengerSelected?.call(passenger);
                        }
                      },
                      overlayWidgets: [
                        _buildInfoOverlay(
                          ctx,
                          passengersList.length,
                          result.markers.length,
                          centerLocation,
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) {
                    // إذا فشل جلب الـ profiles، نحاول استخدام المحطات فقط
                    final result = _buildMarkersFromProfiles(
                      ctx,
                      deduplicatedPassengers,
                      {},
                      stops,
                    );

                    if (result.markers.isEmpty) {
                      return _buildNoLocationState();
                    }

                    final centerLocation = _calculateCenter(result.markers);

                    return ReusableMapWidget(
                      initialLocation: centerLocation,
                      initialZoom: 12.0,
                      markers: result.markers,
                      showMyLocation: true,
                      showMyLocationButton: true,
                      showZoomControls: true,
                      showTraffic: false,
                      enableViewportCulling: true,
                      enableClustering: false,
                      clusteringThreshold: 30,
                      onMarkerTap: (markerId) {
                        final passengerId = int.tryParse(
                          markerId.replaceFirst('passenger_', ''),
                        );
                        if (passengerId != null) {
                          final passenger = passengersList.firstWhere(
                            (p) => p.passengerId == passengerId,
                            orElse: () => passengersList.first,
                          );
                          onPassengerSelected?.call(passenger);
                        }
                      },
                      overlayWidgets: [
                        _buildInfoOverlay(
                          ctx,
                          passengersList.length,
                          result.markers.length,
                          centerLocation,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _buildNoLocationState(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل الركاب',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء علامات الركاب من ملفات التعريف المجلوبة دفعة واحدة
  /// 🎯 الاستراتيجية (الأولوية):
  /// 1. إذا الراكب لديه محطة pickup أو dropoff → تجميع في علامة المحطة
  /// 2. إذا الراكب لديه إحداثيات خاصة (بدون محطة) → علامة فردية
  /// 3. إذا الراكب بدون محطة وبدون إحداثيات → تجاهل (مع تحذير)
  _PassengerMarkersResult _buildMarkersFromProfiles(
    BuildContext context,
    List<PassengerGroupLine> passengers,
    Map<int, DispatcherPassengerProfile> profiles,
    List<ShuttleStop> stops,
  ) {
    final markers = <MapMarkerData>[];

    // 🔒 تتبع الركاب الذين تم إضافتهم (لتجنب التكرار)
    final addedPassengerIds = <int>{};

    // تجميع الركاب حسب المحطات
    final pickupStationPassengers = <int, List<PassengerGroupLine>>{};
    final dropoffStationPassengers = <int, List<PassengerGroupLine>>{};

    debugPrint('🗺️ بدء بناء علامات ${passengers.length} راكب على الخريطة');
    debugPrint('🗺️ عدد profiles المتاحة: ${profiles.length}');
    debugPrint('🗺️ عدد المحطات المتاحة: ${stops.length}');

    // عداد للتشخيص
    int withPickupStop = 0;
    int withDropoffStop = 0;
    int withCoordinatesOnly = 0;
    int withNothing = 0;

    for (final passenger in passengers) {
      // 🔒 تجنب التكرار
      if (addedPassengerIds.contains(passenger.passengerId)) {
        continue;
      }
      addedPassengerIds.add(passenger.passengerId);

      final profile = profiles[passenger.passengerId];

      // ✅ الأولوية 1: المحطة (pickup أو dropoff)
      if (passenger.pickupStopId != null) {
        withPickupStop++;
        pickupStationPassengers
            .putIfAbsent(passenger.pickupStopId!, () => [])
            .add(passenger);
      } else if (passenger.dropoffStopId != null) {
        withDropoffStop++;
        dropoffStationPassengers
            .putIfAbsent(passenger.dropoffStopId!, () => [])
            .add(passenger);
      }
      // ✅ الأولوية 2: إحداثيات خاصة صالحة (بدون محطة)
      // 🔒 يجب أن تكون الإحداثيات غير صفرية
      else if (profile != null &&
          profile.latitude != null &&
          profile.longitude != null &&
          (profile.latitude! != 0.0 || profile.longitude! != 0.0)) {
        withCoordinatesOnly++;
        markers.add(
          PassengerMarkerHelper.createMarker(
            passengerId: passenger.passengerId.toString(),
            location: MapLocation(
              latitude: profile.latitude!,
              longitude: profile.longitude!,
            ),
            passengerName: passenger.passengerName,
            phoneNumber: passenger.primaryGuardianPhone.isNotEmpty
                ? passenger.primaryGuardianPhone
                : passenger.passengerPhone ?? passenger.passengerMobile,
            status: _getPassengerStatus(passenger),
            onTap: () => onPassengerSelected?.call(passenger),
          ),
        );
      }
      // ⚠️ لا محطة ولا إحداثيات صالحة
      else {
        withNothing++;
        final hasZeroCoords =
            profile != null &&
            profile.latitude == 0.0 &&
            profile.longitude == 0.0;
        debugPrint(
          '⚠️ راكب بدون موقع صالح: ${passenger.passengerName} '
          '(id: ${passenger.passengerId}, '
          'pickup: ${passenger.pickupStopId}, '
          'dropoff: ${passenger.dropoffStopId}, '
          'profile: ${profile != null ? "موجود" : "غير موجود"}, '
          'coords: ${profile?.latitude}, ${profile?.longitude}'
          '${hasZeroCoords ? " [إحداثيات صفرية - تم تجاهلها]" : ""})',
        );
      }
    }

    debugPrint(
      '🗺️ تحليل: $withPickupStop مع pickup, '
      '$withDropoffStop مع dropoff, '
      '$withCoordinatesOnly مع إحداثيات فقط, '
      '$withNothing بدون موقع',
    );

    // إضافة علامات المحطات مع عدد الركاب
    debugPrint('🗺️ محطات pickup: ${pickupStationPassengers.keys.toList()}');
    debugPrint('🗺️ محطات dropoff: ${dropoffStationPassengers.keys.toList()}');

    // 🔍 Debug: طباعة معلومات المحطات المتاحة
    for (final stop in stops) {
      debugPrint(
        '🗺️ محطة متاحة: ${stop.name} (id: ${stop.id}, '
        'lat: ${stop.latitude}, lng: ${stop.longitude})',
      );
    }

    for (final entry in pickupStationPassengers.entries) {
      final stopId = entry.key;
      final stationPassengers = entry.value;

      try {
        final stop = stops.firstWhere((s) => s.id == stopId);
        // 🔍 التحقق من أن الإحداثيات صالحة (ليست null وليست 0)
        final hasValidCoordinates =
            stop.hasCoordinates &&
            stop.latitude != 0.0 &&
            stop.longitude != 0.0;

        if (hasValidCoordinates) {
          debugPrint(
            '🗺️ إضافة محطة pickup: ${stop.name} (${stationPassengers.length} راكب) '
            'at (${stop.latitude}, ${stop.longitude})',
          );
          markers.add(
            StationWithCountMarkerHelper.createMarker(
              stationId: 'pickup_$stopId',
              location: MapLocation(
                latitude: stop.latitude!,
                longitude: stop.longitude!,
              ),
              stationName: stop.name,
              passengerCount: stationPassengers.length,
              isPickup: true,
              onTap: () =>
                  _showStationPassengers(context, stop.name, stationPassengers),
            ),
          );
        } else {
          // 🔄 Fallback: استخدام إحداثيات أول راكب في المحطة
          final firstPassengerWithCoords = _findFirstPassengerWithCoordinates(
            stationPassengers,
            profiles,
          );
          if (firstPassengerWithCoords != null) {
            debugPrint(
              '🗺️ إضافة محطة pickup (من إحداثيات راكب): ${stop.name} '
              '(${stationPassengers.length} راكب) '
              'at (${firstPassengerWithCoords.latitude}, ${firstPassengerWithCoords.longitude})',
            );
            markers.add(
              StationWithCountMarkerHelper.createMarker(
                stationId: 'pickup_$stopId',
                location: firstPassengerWithCoords,
                stationName: stop.name,
                passengerCount: stationPassengers.length,
                isPickup: true,
                onTap: () => _showStationPassengers(
                  context,
                  stop.name,
                  stationPassengers,
                ),
              ),
            );
          } else {
            debugPrint(
              '⚠️ محطة pickup بدون إحداثيات وبدون ركاب بإحداثيات: ${stop.name}',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ محطة pickup غير موجودة: $stopId');
      }
    }

    for (final entry in dropoffStationPassengers.entries) {
      final stopId = entry.key;
      final stationPassengers = entry.value;

      // تجنب التكرار إذا كانت المحطة موجودة في pickup
      if (pickupStationPassengers.containsKey(stopId)) {
        debugPrint('🗺️ تجاهل محطة dropoff (موجودة في pickup): $stopId');
        continue;
      }

      try {
        final stop = stops.firstWhere((s) => s.id == stopId);
        // 🔍 التحقق من أن الإحداثيات صالحة (ليست null وليست 0)
        final hasValidCoordinates =
            stop.hasCoordinates &&
            stop.latitude != 0.0 &&
            stop.longitude != 0.0;

        if (hasValidCoordinates) {
          debugPrint(
            '🗺️ إضافة محطة dropoff: ${stop.name} (${stationPassengers.length} راكب) '
            'at (${stop.latitude}, ${stop.longitude})',
          );
          markers.add(
            StationWithCountMarkerHelper.createMarker(
              stationId: 'dropoff_$stopId',
              location: MapLocation(
                latitude: stop.latitude!,
                longitude: stop.longitude!,
              ),
              stationName: stop.name,
              passengerCount: stationPassengers.length,
              isPickup: false,
              onTap: () =>
                  _showStationPassengers(context, stop.name, stationPassengers),
            ),
          );
        } else {
          // 🔄 Fallback: استخدام إحداثيات أول راكب في المحطة
          final firstPassengerWithCoords = _findFirstPassengerWithCoordinates(
            stationPassengers,
            profiles,
          );
          if (firstPassengerWithCoords != null) {
            debugPrint(
              '🗺️ إضافة محطة dropoff (من إحداثيات راكب): ${stop.name} '
              '(${stationPassengers.length} راكب) '
              'at (${firstPassengerWithCoords.latitude}, ${firstPassengerWithCoords.longitude})',
            );
            markers.add(
              StationWithCountMarkerHelper.createMarker(
                stationId: 'dropoff_$stopId',
                location: firstPassengerWithCoords,
                stationName: stop.name,
                passengerCount: stationPassengers.length,
                isPickup: false,
                onTap: () => _showStationPassengers(
                  context,
                  stop.name,
                  stationPassengers,
                ),
              ),
            );
          } else {
            debugPrint(
              '⚠️ محطة dropoff بدون إحداثيات وبدون ركاب بإحداثيات: ${stop.name}',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ محطة dropoff غير موجودة: $stopId');
      }
    }

    final totalStationPassengers =
        pickupStationPassengers.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        ) +
        dropoffStationPassengers.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        );

    debugPrint(
      '🗺️ تم بناء ${markers.length} علامة '
      '(${markers.length - pickupStationPassengers.length - dropoffStationPassengers.length} فردي + '
      '${pickupStationPassengers.length + dropoffStationPassengers.length} محطة مع $totalStationPassengers راكب)',
    );

    return _PassengerMarkersResult(
      markers: markers,
      stationPassengers: {
        ...pickupStationPassengers,
        ...dropoffStationPassengers,
      },
    );
  }

  /// البحث عن أول راكب لديه إحداثيات في قائمة ركاب المحطة
  MapLocation? _findFirstPassengerWithCoordinates(
    List<PassengerGroupLine> stationPassengers,
    Map<int, DispatcherPassengerProfile> profiles,
  ) {
    for (final passenger in stationPassengers) {
      final profile = profiles[passenger.passengerId];
      if (profile != null &&
          profile.latitude != null &&
          profile.longitude != null &&
          profile.latitude != 0.0 &&
          profile.longitude != 0.0) {
        return MapLocation(
          latitude: profile.latitude!,
          longitude: profile.longitude!,
        );
      }
    }
    return null;
  }

  /// عرض ركاب المحطة
  void _showStationPassengers(
    BuildContext context,
    String stationName,
    List<PassengerGroupLine> passengers,
  ) {
    StationPassengersSheet.show(
      context,
      stationName: stationName,
      passengers: passengers,
      onPassengerTap: onPassengerSelected,
    );
  }

  Widget _buildInfoOverlay(
    BuildContext context,
    int totalPassengers,
    int markersCount,
    MapLocation? centerLocation,
  ) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.people_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalPassengers راكب',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    '$markersCount مع موقع GPS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
            // زر تحميل الخريطة offline
            IconButton(
              onPressed: () {
                MapDownloadDialog.show(
                  context,
                  centerLatitude: centerLocation?.latitude,
                  centerLongitude: centerLocation?.longitude,
                  radiusKm: 15.0,
                );
              },
              icon: const Icon(Icons.download_rounded),
              color: AppColors.primary,
              tooltip: 'تحميل الخريطة offline',
            ),
          ],
        ),
      ),
    );
  }

  /// تحديد حالة الراكب
  PassengerStatus _getPassengerStatus(PassengerGroupLine passenger) {
    if (passenger.isUnassigned) {
      return PassengerStatus.waiting;
    }
    // يمكن إضافة منطق إضافي لتحديد الحالة
    return PassengerStatus.waiting;
  }

  /// حساب الموقع المركزي للركاب
  MapLocation _calculateCenter(List<MapMarkerData> markers) {
    if (markers.isEmpty) {
      return CompanyConfig.defaultLocation;
    }

    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final marker in markers) {
      totalLat += marker.location.latitude;
      totalLng += marker.location.longitude;
      count++;
    }

    return MapLocation(latitude: totalLat / count, longitude: totalLng / count);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد ركاب لعرضهم',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLocationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد ركاب بإحداثيات GPS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف إحداثيات GPS للركاب لعرضهم على الخريطة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
