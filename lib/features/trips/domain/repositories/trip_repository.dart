import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/enums/enums.dart';
import '../entities/trip.dart';

/// Trip Repository Interface - ShuttleBee
abstract class TripRepository {
  /// Get trips for a specific date
  Future<Either<Failure, List<Trip>>> getTripsByDate(DateTime date);

  /// Get trips for driver on a specific date
  Future<Either<Failure, List<Trip>>> getDriverTrips(
    int driverId,
    DateTime date, {
    List<TripState>? states,
  });

  /// Get trips for passenger
  Future<Either<Failure, List<Trip>>> getPassengerTrips(int passengerId);

  /// Get trip by ID with lines
  Future<Either<Failure, Trip>> getTripById(int tripId);

  /// Get all trips with filters
  Future<Either<Failure, List<Trip>>> getTrips({
    TripState? state,
    TripType? tripType,
    DateTime? fromDate,
    DateTime? toDate,
    int? driverId,
    int? vehicleId,
    int limit = 50,
    int offset = 0,
  });

  /// Create a new trip
  Future<Either<Failure, Trip>> createTrip(Trip trip);

  /// Update trip
  Future<Either<Failure, Trip>> updateTrip(Trip trip);

  /// Confirm trip (draft → planned)
  Future<Either<Failure, Trip>> confirmTrip(
    int tripId, {
    double? latitude,
    double? longitude,
    int? stopId,
    String? note,
  });

  /// Start trip (planned → ongoing)
  Future<Either<Failure, Trip>> startTrip(int tripId);

  /// Complete trip
  Future<Either<Failure, Trip>> completeTrip(int tripId);

  /// Cancel trip
  Future<Either<Failure, void>> cancelTrip(int tripId);

  /// Update passenger status
  Future<Either<Failure, TripLine>> updatePassengerStatus(
    int tripLineId,
    TripLineStatus status,
  );

  /// Mark passenger as boarded
  Future<Either<Failure, TripLine>> markPassengerBoarded(int tripLineId);

  /// Mark passenger as absent
  Future<Either<Failure, TripLine>> markPassengerAbsent(int tripLineId);

  /// Mark passenger as dropped
  Future<Either<Failure, TripLine>> markPassengerDropped(int tripLineId);

  /// Reset passenger status to planned (undo action for mistakes)
  Future<Either<Failure, TripLine>> resetPassengerToPlanned(int tripLineId);

  /// Add a passenger to a trip
  Future<Either<Failure, TripLine>> addPassengerToTrip({
    required int tripId,
    required int passengerId,
    int seatCount = 1,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
  });

  /// Remove a passenger from a trip
  Future<Either<Failure, void>> removePassengerFromTrip(int tripLineId);

  /// Update a trip line (passenger in trip)
  Future<Either<Failure, TripLine>> updateTripLine({
    required int tripLineId,
    int? seatCount,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
    int? sequence,
  });

  /// Get passengers not in a specific trip (from the trip's group)
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getAvailablePassengersForTrip(int tripId);

  /// Get dashboard statistics
  Future<Either<Failure, TripDashboardStats>> getDashboardStats(DateTime date);

  /// Get manager analytics
  Future<Either<Failure, ManagerAnalytics>> getManagerAnalytics();
}

/// Dashboard Statistics
class TripDashboardStats {
  final int totalTripsToday;
  final int ongoingTrips;
  final int completedTrips;
  final int cancelledTrips;
  final int plannedTrips;
  final int totalPassengers;
  final int boardedPassengers;
  final int absentPassengers;
  final int totalVehicles;
  final int activeVehicles;
  final int totalDrivers;
  final int activeDrivers;

  const TripDashboardStats({
    this.totalTripsToday = 0,
    this.ongoingTrips = 0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    this.plannedTrips = 0,
    this.totalPassengers = 0,
    this.boardedPassengers = 0,
    this.absentPassengers = 0,
    this.totalVehicles = 0,
    this.activeVehicles = 0,
    this.totalDrivers = 0,
    this.activeDrivers = 0,
  });

  factory TripDashboardStats.fromJson(Map<String, dynamic> json) {
    return TripDashboardStats(
      totalTripsToday: json['total_trips_today'] as int? ?? 0,
      ongoingTrips: json['ongoing_trips'] as int? ?? 0,
      completedTrips: json['completed_trips'] as int? ?? 0,
      cancelledTrips: json['cancelled_trips'] as int? ?? 0,
      plannedTrips: json['planned_trips'] as int? ?? 0,
      totalPassengers: json['total_passengers'] as int? ?? 0,
      boardedPassengers: json['boarded_passengers'] as int? ?? 0,
      absentPassengers: json['absent_passengers'] as int? ?? 0,
      totalVehicles: json['total_vehicles'] as int? ?? 0,
      activeVehicles: json['active_vehicles'] as int? ?? 0,
      totalDrivers: json['total_drivers'] as int? ?? 0,
      activeDrivers: json['active_drivers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_trips_today': totalTripsToday,
        'ongoing_trips': ongoingTrips,
        'completed_trips': completedTrips,
        'cancelled_trips': cancelledTrips,
        'planned_trips': plannedTrips,
        'total_passengers': totalPassengers,
        'boarded_passengers': boardedPassengers,
        'absent_passengers': absentPassengers,
        'total_vehicles': totalVehicles,
        'active_vehicles': activeVehicles,
        'total_drivers': totalDrivers,
        'active_drivers': activeDrivers,
      };
}

/// Manager Analytics Data
class ManagerAnalytics {
  final int totalTripsThisMonth;
  final int completedTripsThisMonth;
  final double completionRate;
  final double cancellationRate;
  final int totalPassengersTransported;
  final double averageOccupancyRate;
  final double onTimePercentage;
  final double averageDelayMinutes;
  final double totalDistanceKm;
  final double averageDistancePerTrip;
  final double estimatedFuelCost;

  const ManagerAnalytics({
    this.totalTripsThisMonth = 0,
    this.completedTripsThisMonth = 0,
    this.completionRate = 0,
    this.cancellationRate = 0,
    this.totalPassengersTransported = 0,
    this.averageOccupancyRate = 0,
    this.onTimePercentage = 0,
    this.averageDelayMinutes = 0,
    this.totalDistanceKm = 0,
    this.averageDistancePerTrip = 0,
    this.estimatedFuelCost = 0,
  });

  factory ManagerAnalytics.fromJson(Map<String, dynamic> json) {
    return ManagerAnalytics(
      totalTripsThisMonth: json['total_trips_this_month'] as int? ?? 0,
      completedTripsThisMonth: json['completed_trips_this_month'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0,
      totalPassengersTransported:
          json['total_passengers_transported'] as int? ?? 0,
      averageOccupancyRate:
          (json['average_occupancy_rate'] as num?)?.toDouble() ?? 0,
      onTimePercentage: (json['on_time_percentage'] as num?)?.toDouble() ?? 0,
      averageDelayMinutes:
          (json['average_delay_minutes'] as num?)?.toDouble() ?? 0,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0,
      averageDistancePerTrip:
          (json['average_distance_per_trip'] as num?)?.toDouble() ?? 0,
      estimatedFuelCost: (json['estimated_fuel_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
