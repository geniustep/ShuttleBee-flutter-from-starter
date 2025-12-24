import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../entities/passenger_group_line.dart';

/// Dispatcher Passenger Repository Interface
///
/// Defines operations for managing passenger group lines (shuttle.passenger.group.line).
/// This handles passenger assignments to groups, not the passenger profiles themselves.
/// All operations return Either<Failure, T> for functional error handling.
abstract class DispatcherPassengerRepository {
  /// Get all passengers assigned to a specific group
  ///
  /// [groupId] - The ID of the group
  /// Returns a list of [PassengerGroupLine] or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> getGroupPassengers(
    int groupId,
  );

  /// Get all group assignments for a specific passenger
  ///
  /// [passengerId] - The ID of the passenger
  /// Returns a list of [PassengerGroupLine] or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> getPassengerLines(
    int passengerId,
  );

  /// Sync unassigned passengers with the backend
  ///
  /// Ensures backend creates "unassigned" lines for all shuttle passengers.
  /// This is a best-effort operation that may fail silently.
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> syncUnassignedPassengers();

  /// Get all passengers not assigned to any group
  ///
  /// Returns a list of [PassengerGroupLine] with groupId = null or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> getUnassignedPassengers();

  /// Get passengers assigned to other groups
  ///
  /// [groupId] - If > 0, excludes this specific group. If 0, returns all passengers in any group.
  /// Returns a list of [PassengerGroupLine] or a [Failure]
  Future<Either<Failure, List<PassengerGroupLine>>> getPassengersInOtherGroups(
    int groupId,
  );

  /// Assign a passenger line to a group
  ///
  /// [lineId] - ID of the passenger line
  /// [groupId] - ID of the group to assign to
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> assignLineToGroup({
    required int lineId,
    required int groupId,
  });

  /// Unassign a passenger line from its group
  ///
  /// [lineId] - ID of the passenger line
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> unassignLine({required int lineId});

  /// Update a passenger line
  ///
  /// [lineId] - ID of the passenger line to update
  /// [seatCount] - Number of seats (optional)
  /// [sequence] - Display sequence (optional)
  /// [notes] - Additional notes (optional)
  /// [pickupStopId] - Pickup stop ID (optional)
  /// [dropoffStopId] - Dropoff stop ID (optional)
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> updateLine({
    required int lineId,
    int? seatCount,
    int? sequence,
    String? notes,
    int? pickupStopId,
    int? dropoffStopId,
  });

  /// Delete a passenger line
  ///
  /// [lineId] - ID of the passenger line to delete
  /// Returns void or a [Failure]
  Future<Either<Failure, void>> deleteLine({required int lineId});
}
