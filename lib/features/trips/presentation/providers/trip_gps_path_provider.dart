import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shuttlebee/presentation/providers/shuttlebee_api_providers.dart';

class TripGpsPathState {
  final List<LatLng> points;
  final DateTime? lastTimestamp;
  final bool isLoading;

  const TripGpsPathState({
    this.points = const [],
    this.lastTimestamp,
    this.isLoading = false,
  });

  TripGpsPathState copyWith({
    List<LatLng>? points,
    DateTime? lastTimestamp,
    bool? isLoading,
  }) {
    return TripGpsPathState(
      points: points ?? this.points,
      lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final tripGpsPathProvider = StateNotifierProvider.autoDispose
    .family<TripGpsPathController, TripGpsPathState, int>((ref, tripId) {
  final controller = TripGpsPathController(ref, tripId);
  ref.onDispose(controller.dispose);
  return controller;
});

class TripGpsPathController extends StateNotifier<TripGpsPathState> {
  final Ref _ref;
  final int _tripId;
  Timer? _timer;
  bool _initialFetched = false;

  TripGpsPathController(this._ref, this._tripId)
      : super(const TripGpsPathState(isLoading: true)) {
    _startPolling();
  }

  void _startPolling() {
    // Poll every 5 seconds while the screen is open.
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
    // Fire immediately.
    scheduleMicrotask(_tick);
  }

  Future<void> _tick() async {
    final api = _ref.read(shuttleBeeApiServiceProvider);
    try {
      final since = _initialFetched ? state.lastTimestamp : null;
      final points =
          await api.getTripGpsPoints(_tripId, since: since, limit: 500);

      // If backend doesn't send timestamps, incremental mode isn't possible.
      final hasAnyTimestamp = points.any((p) => p.timestamp != null);
      if (!_initialFetched) {
        _initialFetched = true;
      }

      if (points.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final nextLatLngs = <LatLng>[];
      DateTime? maxTs = state.lastTimestamp;

      for (final p in points) {
        final lat = p.latitude;
        final lng = p.longitude;
        if (lat < -90 || lat > 90) continue;
        if (lng < -180 || lng > 180) continue;
        if (lat.abs() < 0.00001 && lng.abs() < 0.00001) continue;
        nextLatLngs.add(LatLng(lat, lng));
        final ts = p.timestamp;
        if (ts != null && (maxTs == null || ts.isAfter(maxTs))) {
          maxTs = ts;
        }
      }

      final merged = <LatLng>[
        ...state.points,
        ...nextLatLngs,
      ];

      // Cheap de-dup for consecutive duplicates.
      final deduped = <LatLng>[];
      for (final pt in merged) {
        if (deduped.isEmpty) {
          deduped.add(pt);
        } else {
          final prev = deduped.last;
          if ((prev.latitude - pt.latitude).abs() < 1e-7 &&
              (prev.longitude - pt.longitude).abs() < 1e-7) {
            continue;
          }
          deduped.add(pt);
        }
      }

      state = state.copyWith(
        points: deduped,
        lastTimestamp: hasAnyTimestamp ? maxTs : state.lastTimestamp,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
