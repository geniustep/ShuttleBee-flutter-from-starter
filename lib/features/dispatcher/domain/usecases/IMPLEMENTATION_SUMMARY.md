# Dispatcher Use Cases - Implementation Summary

## Overview

Successfully created a comprehensive Use Cases layer for the dispatcher feature following Clean Architecture principles. This layer encapsulates all business logic and provides a clean interface between the presentation and data layers.

## Files Created

**Total: 22 Dart files**

### Directory Structure

```
usecases/
├── README.md                              # Comprehensive documentation
├── usecases.dart                          # Main barrel file
│
├── holidays/                              # 6 files
│   ├── holidays.dart                      # Barrel file
│   ├── get_holidays.dart
│   ├── get_holiday_by_id.dart
│   ├── create_holiday.dart
│   ├── update_holiday.dart
│   └── delete_holiday.dart
│
├── passengers/                            # 8 files
│   ├── passengers.dart                    # Barrel file
│   ├── create_passenger.dart
│   ├── get_passenger_by_id.dart
│   ├── update_passenger.dart
│   ├── delete_passenger.dart
│   ├── update_temporary_location.dart
│   ├── clear_temporary_location.dart
│   └── update_guardian_info.dart
│
└── passenger_lines/                       # 7 files
    ├── passenger_lines.dart               # Barrel file
    ├── get_group_passengers.dart
    ├── get_passenger_lines.dart
    ├── get_unassigned_passengers.dart
    ├── assign_passenger_to_group.dart
    ├── unassign_passenger.dart
    └── update_passenger_line.dart
```

## Use Cases Breakdown

### 1. Holidays Use Cases (5 use cases)

Manages global holidays that affect trip scheduling.

| Use Case | Purpose | Parameters | Returns |
|----------|---------|------------|---------|
| `GetHolidays` | Fetch all holidays | `activeOnly: bool` | `List<DispatcherHoliday>` |
| `GetHolidayById` | Get specific holiday | `holidayId: int` | `DispatcherHoliday` |
| `CreateHoliday` | Create new holiday | `CreateHolidayParams` | `DispatcherHoliday` |
| `UpdateHoliday` | Update holiday | `UpdateHolidayParams` | `bool` |
| `DeleteHoliday` | Delete holiday | `holidayId: int` | `bool` |

**Parameter Classes:**
- `CreateHolidayParams` - name, startDate, endDate, notes
- `UpdateHolidayParams` - holidayId, name, startDate, endDate, notes, active

---

### 2. Passengers Use Cases (7 use cases)

Manages passenger profiles (res.partner records).

| Use Case | Purpose | Parameters | Returns |
|----------|---------|------------|---------|
| `CreatePassenger` | Create passenger profile | `CreatePassengerParams` | `int` (passenger ID) |
| `GetPassengerById` | Get passenger profile | `passengerId: int` | `DispatcherPassengerProfile` |
| `UpdatePassenger` | Update passenger profile | `UpdatePassengerParams` | `void` |
| `DeletePassenger` | Delete passenger | `passengerId: int` | `void` |
| `UpdateTemporaryLocation` | Set temporary address | `UpdateTemporaryLocationParams` | `void` |
| `ClearTemporaryLocation` | Clear temporary address | `passengerId: int` | `void` |
| `UpdateGuardianInfo` | Update guardian info | `UpdateGuardianInfoParams` | `void` |

**Parameter Classes:**
- `CreatePassengerParams` - name, phone, mobile, guardianPhone, guardianEmail, street, city, notes, latitude, longitude, useGpsForPickup, useGpsForDropoff, tripDirection, autoNotification
- `UpdatePassengerParams` - passengerId + all optional fields
- `UpdateTemporaryLocationParams` - passengerId, temporaryAddress, temporaryLatitude, temporaryLongitude, temporaryContactName, temporaryContactPhone
- `UpdateGuardianInfoParams` - passengerId, hasGuardian, fatherName, fatherPhone, motherName, motherPhone

---

### 3. Passenger Lines Use Cases (6 use cases)

Manages passenger assignments to groups (shuttle.passenger.group.line records).

| Use Case | Purpose | Parameters | Returns |
|----------|---------|------------|---------|
| `GetGroupPassengers` | Get passengers in group | `groupId: int` | `List<PassengerGroupLine>` |
| `GetPassengerLines` | Get passenger's assignments | `passengerId: int` | `List<PassengerGroupLine>` |
| `GetUnassignedPassengers` | Get unassigned passengers | `syncFirst: bool` | `List<PassengerGroupLine>` |
| `AssignPassengerToGroup` | Assign to group | `AssignPassengerToGroupParams` | `void` |
| `UnassignPassenger` | Remove from group | `lineId: int` | `void` |
| `UpdatePassengerLine` | Update line details | `UpdatePassengerLineParams` | `void` |

**Parameter Classes:**
- `AssignPassengerToGroupParams` - lineId, groupId
- `UpdatePassengerLineParams` - lineId, seatCount, sequence, notes, pickupStopId, dropoffStopId

---

## Architecture Compliance

### Clean Architecture Principles

✅ **Dependency Rule**: Use cases depend only on repository interfaces (abstractions), not implementations
✅ **Single Responsibility**: Each use case handles one specific business operation
✅ **Separation of Concerns**: Business logic is isolated from UI and data layers
✅ **Testability**: All use cases are easily testable with mocked repositories
✅ **Functional Error Handling**: All use cases return `Either<Failure, T>`

### Code Quality Features

✅ **Type Safety**: Strong typing throughout with Dart's null safety
✅ **Immutability**: All parameter classes are immutable (const constructors)
✅ **Documentation**: Comprehensive inline documentation for all classes and methods
✅ **Consistency**: Uniform pattern across all use cases
✅ **Readability**: Clear naming conventions and structured code

### Repository Integration

All use cases properly integrate with existing repositories:

- **DispatcherHolidayRepository** - 5 use cases
- **DispatcherPartnerRepository** - 7 use cases
- **DispatcherPassengerRepository** - 6 use cases

### Error Handling

All use cases leverage the existing error handling framework:

- Uses `Failure` base class from `core/error_handling/failures.dart`
- Returns `Either<Failure, T>` from `dartz` package
- Supports all failure types: `ServerFailure`, `NetworkFailure`, `ValidationFailure`, etc.

---

## Usage Patterns

### Simple Import (Category-Specific)

```dart
// Import all holiday use cases
import 'package:your_app/features/dispatcher/domain/usecases/holidays/holidays.dart';

// Import all passenger use cases
import 'package:your_app/features/dispatcher/domain/usecases/passengers/passengers.dart';

// Import all passenger line use cases
import 'package:your_app/features/dispatcher/domain/usecases/passenger_lines/passenger_lines.dart';
```

### Comprehensive Import

```dart
// Import everything at once
import 'package:your_app/features/dispatcher/domain/usecases/usecases.dart';
```

### Individual Import

```dart
// Import specific use cases
import 'package:your_app/features/dispatcher/domain/usecases/holidays/get_holidays.dart';
import 'package:your_app/features/dispatcher/domain/usecases/passengers/create_passenger.dart';
```

---

## Integration Checklist

### ✅ Completed

- [x] Created all 18 use case classes
- [x] Created 4 barrel files for easy imports
- [x] Added comprehensive documentation (README.md)
- [x] Followed Clean Architecture principles
- [x] Integrated with existing repositories
- [x] Used existing error handling framework
- [x] Applied consistent patterns across all use cases
- [x] Added detailed inline documentation

### 🔲 Next Steps (Recommended)

- [ ] Set up dependency injection (GetIt or similar)
- [ ] Create Blocs/Cubits that use these use cases
- [ ] Write unit tests for all use cases
- [ ] Create integration tests with repository mocks
- [ ] Implement data layer (repository implementations)
- [ ] Create UI screens that interact with Blocs

---

## Example Usage in Bloc

```dart
class HolidayManagementBloc extends Bloc<HolidayEvent, HolidayState> {
  final GetHolidays getHolidays;
  final CreateHoliday createHoliday;
  final UpdateHoliday updateHoliday;
  final DeleteHoliday deleteHoliday;

  HolidayManagementBloc({
    required this.getHolidays,
    required this.createHoliday,
    required this.updateHoliday,
    required this.deleteHoliday,
  }) : super(HolidayInitial()) {
    on<LoadHolidaysEvent>(_onLoadHolidays);
    on<CreateHolidayEvent>(_onCreateHoliday);
    on<UpdateHolidayEvent>(_onUpdateHoliday);
    on<DeleteHolidayEvent>(_onDeleteHoliday);
  }

  Future<void> _onLoadHolidays(
    LoadHolidaysEvent event,
    Emitter<HolidayState> emit,
  ) async {
    emit(HolidayLoading());

    final result = await getHolidays(activeOnly: event.activeOnly);

    result.fold(
      (failure) => emit(HolidayError(failure.message)),
      (holidays) => emit(HolidayLoaded(holidays)),
    );
  }

  Future<void> _onCreateHoliday(
    CreateHolidayEvent event,
    Emitter<HolidayState> emit,
  ) async {
    emit(HolidayCreating());

    final params = CreateHolidayParams(
      name: event.name,
      startDate: event.startDate,
      endDate: event.endDate,
      notes: event.notes,
    );

    final result = await createHoliday(params);

    result.fold(
      (failure) => emit(HolidayError(failure.message)),
      (holiday) {
        emit(HolidayCreated(holiday));
        add(LoadHolidaysEvent()); // Reload list
      },
    );
  }
}
```

---

## Testing Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

void main() {
  late GetHolidays useCase;
  late MockDispatcherHolidayRepository mockRepository;

  setUp(() {
    mockRepository = MockDispatcherHolidayRepository();
    useCase = GetHolidays(mockRepository);
  });

  group('GetHolidays', () {
    final tHolidays = [
      DispatcherHoliday(
        id: 1,
        name: 'Eid Al-Fitr',
        startDate: DateTime(2025, 4, 1),
        endDate: DateTime(2025, 4, 3),
        active: true,
      ),
      DispatcherHoliday(
        id: 2,
        name: 'National Day',
        startDate: DateTime(2025, 9, 23),
        endDate: DateTime(2025, 9, 23),
        active: true,
      ),
    ];

    test('should get holidays from the repository', () async {
      // Arrange
      when(mockRepository.getHolidays(activeOnly: true))
          .thenAnswer((_) async => Right(tHolidays));

      // Act
      final result = await useCase(activeOnly: true);

      // Assert
      expect(result, Right(tHolidays));
      verify(mockRepository.getHolidays(activeOnly: true));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      final tFailure = ServerFailure(message: 'Server error');
      when(mockRepository.getHolidays(activeOnly: true))
          .thenAnswer((_) async => Left(tFailure));

      // Act
      final result = await useCase(activeOnly: true);

      // Assert
      expect(result, Left(tFailure));
      verify(mockRepository.getHolidays(activeOnly: true));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

---

## File Locations

All files are located at:
```
D:\flutter\app\ShuttleBee-flutter-from-starter\lib\features\dispatcher\domain\usecases\
```

## Dependencies

Required packages (already in project):
- `dartz` - For Either monad and functional error handling
- `flutter` - For Flutter framework

---

## Summary

This implementation provides a solid foundation for the dispatcher feature's business logic layer. The use cases are:

- **Well-structured** - Following Clean Architecture principles
- **Type-safe** - Leveraging Dart's strong typing and null safety
- **Testable** - Easy to mock and test in isolation
- **Maintainable** - Clear separation of concerns
- **Scalable** - Easy to extend with new use cases
- **Documented** - Comprehensive documentation and examples

The use cases layer is now ready to be integrated with the presentation layer (Blocs) and data layer (repository implementations).
