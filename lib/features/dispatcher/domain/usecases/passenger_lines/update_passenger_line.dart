import 'package:dartz/dartz.dart';
import '../../../../../core/error_handling/failures.dart';
import '../../repositories/dispatcher_passenger_repository.dart';

/// Parameters for updating a passenger line
class UpdatePassengerLineParams {
  final int lineId;
  final int? seatCount;
  final int? sequence;
  final String? notes;
  final int? pickupStopId;
  final int? dropoffStopId;

  const UpdatePassengerLineParams({
    required this.lineId,
    this.seatCount,
    this.sequence,
    this.notes,
    this.pickupStopId,
    this.dropoffStopId,
  });
}

/// Use Case: Update Passenger Line
///
/// Updates details of a passenger line including seats, sequence, stops, and notes.
/// This allows modifying passenger-specific settings within a group.
/// Follows Clean Architecture principles by encapsulating business logic.
class UpdatePassengerLine {
  final DispatcherPassengerRepository repository;

  const UpdatePassengerLine(this.repository);

  /// Execute the use case
  ///
  /// [params] - The line update parameters
  /// Returns void on success or a [Failure]
  Future<Either<Failure, void>> call(UpdatePassengerLineParams params) async {
    return await repository.updateLine(
      lineId: params.lineId,
      seatCount: params.seatCount,
      sequence: params.sequence,
      notes: params.notes,
      pickupStopId: params.pickupStopId,
      dropoffStopId: params.dropoffStopId,
    );
  }
}
