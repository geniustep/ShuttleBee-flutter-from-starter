# Dispatcher Use Cases - Quick Reference Guide

## Import Statements

```dart
// Import all use cases
import 'package:your_app/features/dispatcher/domain/usecases/usecases.dart';

// Import by category
import 'package:your_app/features/dispatcher/domain/usecases/holidays/holidays.dart';
import 'package:your_app/features/dispatcher/domain/usecases/passengers/passengers.dart';
import 'package:your_app/features/dispatcher/domain/usecases/passenger_lines/passenger_lines.dart';
```

---

## Use Cases Quick Reference

### Holidays

```dart
// Get all active holidays
final result = await getHolidays(activeOnly: true);

// Get specific holiday
final result = await getHolidayById(1);

// Create holiday
final params = CreateHolidayParams(
  name: 'Eid Al-Fitr',
  startDate: DateTime(2025, 4, 1),
  endDate: DateTime(2025, 4, 3),
  notes: 'Islamic holiday',
);
final result = await createHoliday(params);

// Update holiday
final params = UpdateHolidayParams(
  holidayId: 1,
  name: 'Updated Name',
  startDate: DateTime(2025, 4, 1),
  endDate: DateTime(2025, 4, 3),
  active: true,
);
final result = await updateHoliday(params);

// Delete holiday
final result = await deleteHoliday(1);
```

---

### Passengers

```dart
// Create passenger
final params = CreatePassengerParams(
  name: 'Ahmed Ali',
  phone: '+966501234567',
  street: '123 Main St',
  city: 'Riyadh',
  latitude: 24.7136,
  longitude: 46.6753,
  tripDirection: 'both',
  autoNotification: true,
);
final result = await createPassenger(params);

// Get passenger by ID
final result = await getPassengerById(1);

// Update passenger
final params = UpdatePassengerParams(
  passengerId: 1,
  name: 'Ahmed Ali Updated',
  phone: '+966501234567',
  city: 'Jeddah',
);
final result = await updatePassenger(params);

// Delete passenger
final result = await deletePassenger(1);

// Update temporary location
final params = UpdateTemporaryLocationParams(
  passengerId: 1,
  temporaryAddress: 'Temporary address',
  temporaryLatitude: 24.7136,
  temporaryLongitude: 46.6753,
  temporaryContactName: 'Uncle Ahmad',
  temporaryContactPhone: '+966509876543',
);
final result = await updateTemporaryLocation(params);

// Clear temporary location
final result = await clearTemporaryLocation(1);

// Update guardian info
final params = UpdateGuardianInfoParams(
  passengerId: 1,
  hasGuardian: true,
  fatherName: 'Ali Ahmed',
  fatherPhone: '+966501111111',
  motherName: 'Fatima Ali',
  motherPhone: '+966502222222',
);
final result = await updateGuardianInfo(params);
```

---

### Passenger Lines (Group Assignments)

```dart
// Get all passengers in a group
final result = await getGroupPassengers(1);

// Get all group assignments for a passenger
final result = await getPassengerLines(1);

// Get unassigned passengers (with optional sync)
final result = await getUnassignedPassengers(syncFirst: true);

// Assign passenger to group
final params = AssignPassengerToGroupParams(
  lineId: 1,
  groupId: 5,
);
final result = await assignPassengerToGroup(params);

// Unassign passenger from group
final result = await unassignPassenger(1);

// Update passenger line details
final params = UpdatePassengerLineParams(
  lineId: 1,
  seatCount: 2,
  sequence: 10,
  notes: 'Needs special assistance',
  pickupStopId: 3,
  dropoffStopId: 7,
);
final result = await updatePassengerLine(params);
```

---

## Parameter Classes Cheat Sheet

### CreateHolidayParams
```dart
CreateHolidayParams({
  required String name,
  required DateTime startDate,
  required DateTime endDate,
  String? notes,
})
```

### UpdateHolidayParams
```dart
UpdateHolidayParams({
  required int holidayId,
  required String name,
  required DateTime startDate,
  required DateTime endDate,
  String? notes,
  bool? active,
})
```

### CreatePassengerParams
```dart
CreatePassengerParams({
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
})
```

### UpdatePassengerParams
```dart
UpdatePassengerParams({
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
})
```

### UpdateTemporaryLocationParams
```dart
UpdateTemporaryLocationParams({
  required int passengerId,
  String? temporaryAddress,
  double? temporaryLatitude,
  double? temporaryLongitude,
  String? temporaryContactName,
  String? temporaryContactPhone,
})
```

### UpdateGuardianInfoParams
```dart
UpdateGuardianInfoParams({
  required int passengerId,
  bool? hasGuardian,
  String? fatherName,
  String? fatherPhone,
  String? motherName,
  String? motherPhone,
})
```

### AssignPassengerToGroupParams
```dart
AssignPassengerToGroupParams({
  required int lineId,
  required int groupId,
})
```

### UpdatePassengerLineParams
```dart
UpdatePassengerLineParams({
  required int lineId,
  int? seatCount,
  int? sequence,
  String? notes,
  int? pickupStopId,
  int? dropoffStopId,
})
```

---

## Error Handling Pattern

All use cases return `Either<Failure, T>`. Handle results like this:

```dart
final result = await useCase(params);

result.fold(
  (failure) {
    // Handle error
    print('Error: ${failure.message}');
    // Show error to user
  },
  (data) {
    // Handle success
    print('Success!');
    // Update UI with data
  },
);
```

---

## Dependency Injection Example (GetIt)

```dart
void setupUseCases() {
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

---

## Bloc Constructor Example

```dart
class PassengerManagementBloc extends Bloc<PassengerEvent, PassengerState> {
  final CreatePassenger createPassenger;
  final GetPassengerById getPassengerById;
  final UpdatePassenger updatePassenger;
  final DeletePassenger deletePassenger;
  final UpdateTemporaryLocation updateTemporaryLocation;
  final ClearTemporaryLocation clearTemporaryLocation;
  final UpdateGuardianInfo updateGuardianInfo;

  PassengerManagementBloc({
    required this.createPassenger,
    required this.getPassengerById,
    required this.updatePassenger,
    required this.deletePassenger,
    required this.updateTemporaryLocation,
    required this.clearTemporaryLocation,
    required this.updateGuardianInfo,
  }) : super(PassengerInitial());
}
```

---

## Common Patterns

### Loading List
```dart
Future<void> loadData() async {
  emit(LoadingState());

  final result = await getHolidays(activeOnly: true);

  result.fold(
    (failure) => emit(ErrorState(failure.message)),
    (items) => emit(LoadedState(items)),
  );
}
```

### Creating Item
```dart
Future<void> createItem(CreateParams params) async {
  emit(CreatingState());

  final result = await createUseCase(params);

  result.fold(
    (failure) => emit(ErrorState(failure.message)),
    (item) {
      emit(CreatedState(item));
      // Optionally reload list
      add(LoadListEvent());
    },
  );
}
```

### Updating Item
```dart
Future<void> updateItem(UpdateParams params) async {
  emit(UpdatingState());

  final result = await updateUseCase(params);

  result.fold(
    (failure) => emit(ErrorState(failure.message)),
    (_) {
      emit(UpdatedState());
      // Reload list or single item
      add(LoadListEvent());
    },
  );
}
```

### Deleting Item
```dart
Future<void> deleteItem(int id) async {
  emit(DeletingState());

  final result = await deleteUseCase(id);

  result.fold(
    (failure) => emit(ErrorState(failure.message)),
    (_) {
      emit(DeletedState());
      // Reload list
      add(LoadListEvent());
    },
  );
}
```

---

## Testing Pattern

```dart
void main() {
  late UseCase useCase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    useCase = UseCase(mockRepository);
  });

  test('should return data when repository call is successful', () async {
    // Arrange
    final tData = /* test data */;
    when(mockRepository.method())
        .thenAnswer((_) async => Right(tData));

    // Act
    final result = await useCase(/* params */);

    // Assert
    expect(result, Right(tData));
    verify(mockRepository.method());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository call fails', () async {
    // Arrange
    final tFailure = ServerFailure(message: 'Error');
    when(mockRepository.method())
        .thenAnswer((_) async => Left(tFailure));

    // Act
    final result = await useCase(/* params */);

    // Assert
    expect(result, Left(tFailure));
    verify(mockRepository.method());
    verifyNoMoreInteractions(mockRepository);
  });
}
```

---

## File Paths

```
D:\flutter\app\ShuttleBee-flutter-from-starter\lib\features\dispatcher\domain\usecases\
```

---

## Related Files

- **Entities**: `../entities/`
- **Repositories**: `../repositories/`
- **Data Layer**: `../../data/`
- **Presentation Layer**: `../../presentation/`
