# Dispatcher Use Cases Layer

This directory contains the **Use Cases** (also known as Interactors) for the Dispatcher feature, following **Clean Architecture** principles.

## Architecture Overview

The Use Cases layer sits between the Presentation layer and the Data layer, encapsulating all business logic and orchestrating the flow of data. Each use case represents a single business operation.

```
Presentation Layer (UI/Bloc)
        ↓
   Use Cases Layer ← You are here
        ↓
Repository Interfaces (Domain)
        ↓
   Data Layer (Implementation)
```

## Folder Structure

```
usecases/
├── holidays/              # Holiday management use cases
│   ├── create_holiday.dart
│   ├── delete_holiday.dart
│   ├── get_holiday_by_id.dart
│   ├── get_holidays.dart
│   └── update_holiday.dart
│
├── passengers/            # Passenger profile management use cases
│   ├── create_passenger.dart
│   ├── delete_passenger.dart
│   ├── get_passenger_by_id.dart
│   ├── update_passenger.dart
│   ├── update_temporary_location.dart
│   ├── clear_temporary_location.dart
│   └── update_guardian_info.dart
│
└── passenger_lines/       # Passenger-to-group assignment use cases
    ├── get_group_passengers.dart
    ├── get_passenger_lines.dart
    ├── get_unassigned_passengers.dart
    ├── assign_passenger_to_group.dart
    ├── unassign_passenger.dart
    └── update_passenger_line.dart
```

## Use Case Pattern

Each use case follows a consistent pattern:

### 1. Simple Use Cases (Single Parameter)

```dart
class GetHolidayById {
  final DispatcherHolidayRepository repository;

  const GetHolidayById(this.repository);

  Future<Either<Failure, DispatcherHoliday>> call(int holidayId) async {
    return await repository.getHolidayById(holidayId);
  }
}
```

### 2. Complex Use Cases (Multiple Parameters)

```dart
class CreateHolidayParams {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;

  const CreateHolidayParams({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.notes,
  });
}

class CreateHoliday {
  final DispatcherHolidayRepository repository;

  const CreateHoliday(this.repository);

  Future<Either<Failure, DispatcherHoliday>> call(
    CreateHolidayParams params,
  ) async {
    return await repository.createHoliday(
      name: params.name,
      startDate: params.startDate,
      endDate: params.endDate,
      notes: params.notes,
    );
  }
}
```

## Use Case Categories

### Holidays (5 use cases)

Manage global holidays that affect trip scheduling:

- **GetHolidays** - Fetch all holidays with optional filtering
- **GetHolidayById** - Get a specific holiday
- **CreateHoliday** - Create a new holiday
- **UpdateHoliday** - Update an existing holiday
- **DeleteHoliday** - Delete a holiday

### Passengers (7 use cases)

Manage passenger profiles (res.partner records):

- **CreatePassenger** - Create a new passenger profile
- **GetPassengerById** - Get passenger profile by ID
- **UpdatePassenger** - Update passenger profile
- **DeletePassenger** - Delete a passenger
- **UpdateTemporaryLocation** - Set temporary pickup/dropoff location
- **ClearTemporaryLocation** - Clear temporary location
- **UpdateGuardianInfo** - Update guardian/parent information

### Passenger Lines (6 use cases)

Manage passenger assignments to groups (shuttle.passenger.group.line records):

- **GetGroupPassengers** - Get all passengers in a group
- **GetPassengerLines** - Get all group assignments for a passenger
- **GetUnassignedPassengers** - Get passengers not assigned to any group
- **AssignPassengerToGroup** - Assign a passenger to a group
- **UnassignPassenger** - Remove passenger from their group
- **UpdatePassengerLine** - Update line details (seats, stops, notes)

## Usage Examples

### Using in a Bloc

```dart
class HolidayBloc extends Bloc<HolidayEvent, HolidayState> {
  final GetHolidays getHolidays;
  final CreateHoliday createHoliday;
  final DeleteHoliday deleteHoliday;

  HolidayBloc({
    required this.getHolidays,
    required this.createHoliday,
    required this.deleteHoliday,
  }) : super(HolidayInitial()) {
    on<LoadHolidays>(_onLoadHolidays);
    on<CreateNewHoliday>(_onCreateHoliday);
    on<DeleteHolidayById>(_onDeleteHoliday);
  }

  Future<void> _onLoadHolidays(
    LoadHolidays event,
    Emitter<HolidayState> emit,
  ) async {
    emit(HolidayLoading());

    final result = await getHolidays(activeOnly: true);

    result.fold(
      (failure) => emit(HolidayError(failure.message)),
      (holidays) => emit(HolidayLoaded(holidays)),
    );
  }

  Future<void> _onCreateHoliday(
    CreateNewHoliday event,
    Emitter<HolidayState> emit,
  ) async {
    final params = CreateHolidayParams(
      name: event.name,
      startDate: event.startDate,
      endDate: event.endDate,
      notes: event.notes,
    );

    final result = await createHoliday(params);

    result.fold(
      (failure) => emit(HolidayError(failure.message)),
      (holiday) => add(LoadHolidays()), // Reload list
    );
  }
}
```

### Dependency Injection Setup

```dart
// In your service locator (e.g., GetIt)
void initDispatcherUseCases() {
  // Holidays
  sl.registerLazySingleton(() => GetHolidays(sl()));
  sl.registerLazySingleton(() => GetHolidayById(sl()));
  sl.registerLazySingleton(() => CreateHoliday(sl()));
  sl.registerLazySingleton(() => UpdateHoliday(sl()));
  sl.registerLazySingleton(() => DeleteHoliday(sl()));

  // Passengers
  sl.registerLazySingleton(() => CreatePassenger(sl()));
  sl.registerLazySingleton(() => GetPassengerById(sl()));
  sl.registerLazySingleton(() => UpdatePassenger(sl()));
  sl.registerLazySingleton(() => DeletePassenger(sl()));
  sl.registerLazySingleton(() => UpdateTemporaryLocation(sl()));
  sl.registerLazySingleton(() => ClearTemporaryLocation(sl()));
  sl.registerLazySingleton(() => UpdateGuardianInfo(sl()));

  // Passenger Lines
  sl.registerLazySingleton(() => GetGroupPassengers(sl()));
  sl.registerLazySingleton(() => GetPassengerLines(sl()));
  sl.registerLazySingleton(() => GetUnassignedPassengers(sl()));
  sl.registerLazySingleton(() => AssignPassengerToGroup(sl()));
  sl.registerLazySingleton(() => UnassignPassenger(sl()));
  sl.registerLazySingleton(() => UpdatePassengerLine(sl()));
}
```

### Easy Imports with Barrel Files

```dart
// Import all holiday use cases
import 'package:your_app/features/dispatcher/domain/usecases/holidays/holidays.dart';

// Import all passenger use cases
import 'package:your_app/features/dispatcher/domain/usecases/passengers/passengers.dart';

// Import all passenger line use cases
import 'package:your_app/features/dispatcher/domain/usecases/passenger_lines/passenger_lines.dart';

// Or import everything at once
import 'package:your_app/features/dispatcher/domain/usecases/usecases.dart';
```

## Design Principles

### 1. Single Responsibility
Each use case does ONE thing and does it well.

### 2. Dependency Inversion
Use cases depend on repository interfaces (abstractions), not concrete implementations.

### 3. Functional Error Handling
All use cases return `Either<Failure, T>` from the `dartz` package for type-safe error handling.

### 4. Testability
Use cases are easily testable by mocking the repository dependency.

### 5. Reusability
Use cases can be reused across different parts of the UI (screens, widgets, blocs).

## Testing Use Cases

Example test:

```dart
void main() {
  late GetHolidays useCase;
  late MockDispatcherHolidayRepository mockRepository;

  setUp(() {
    mockRepository = MockDispatcherHolidayRepository();
    useCase = GetHolidays(mockRepository);
  });

  test('should return list of holidays from repository', () async {
    // Arrange
    final tHolidays = [
      DispatcherHoliday(
        id: 1,
        name: 'Eid',
        startDate: DateTime(2025, 6, 15),
        endDate: DateTime(2025, 6, 17),
        active: true,
      ),
    ];
    when(mockRepository.getHolidays(activeOnly: true))
        .thenAnswer((_) async => Right(tHolidays));

    // Act
    final result = await useCase(activeOnly: true);

    // Assert
    expect(result, Right(tHolidays));
    verify(mockRepository.getHolidays(activeOnly: true));
    verifyNoMoreInteractions(mockRepository);
  });
}
```

## Benefits of This Architecture

1. **Separation of Concerns** - Business logic is isolated from UI and data layers
2. **Testability** - Easy to unit test without dependencies on UI or database
3. **Maintainability** - Changes to business rules are localized to use cases
4. **Reusability** - Use cases can be shared across multiple UI components
5. **Type Safety** - Compile-time checking with strong typing and Either monad
6. **Scalability** - Easy to add new use cases without affecting existing code

## Next Steps

After implementing use cases, you should:

1. Create repositories implementations in the data layer
2. Create Blocs/Cubits in the presentation layer that use these use cases
3. Set up dependency injection
4. Write tests for all use cases
5. Document any business rules or validation logic

## Related Documentation

- [Domain Layer](../README.md)
- [Entities](../entities/README.md)
- [Repositories](../repositories/README.md)
- [Data Layer](../../data/README.md)
- [Presentation Layer](../../presentation/README.md)
