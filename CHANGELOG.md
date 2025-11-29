# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Odoo 18 Action Methods
- Added `validate()` method for confirming/validating records
- Added `approve()` method for approving records
- Added `reject()` method for rejecting records
- Added `done()` method for marking records as done
- Added `assign()` method for assigning records to users
- Added `unlock()` method for unlocking locked records
- Added `executeButtonAction()` method for executing custom button actions

#### Event Bus System
- Implemented comprehensive Event Bus service for application-wide events
- Added 40+ event types covering record operations, user actions, sync, network, and notifications
- Created `BusEvent` class with factory methods for common events
- Implemented event filtering by type and model
- Added custom event support

#### Trigger System
- Implemented automated trigger system based on events
- Added `TriggerCondition` for defining when triggers should execute
- Created `TriggerService` for managing and executing triggers
- Added support for custom condition functions
- Implemented enable/disable functionality for triggers

#### Multi-Company Support
- Enhanced `OdooContextManager` with multi-company features
- Added `setUserContext()` for easy context initialization
- Implemented `switchCompany()` for company switching
- Added `getActiveCompanies()` to retrieve accessible companies
- Created `hasAccessToCompany()` for permission checking
- Added `getContextWithCompany()` for company-specific operations
- Implemented `getMultiCompanyContext()` for multi-company operations

#### Enhanced Error Handling
- Created `OdooErrorHandler` for BridgeCore exception handling
- Added Odoo-specific exception types:
  - `OdooException` - Base Odoo exception
  - `OdooValidationException` - Validation errors
  - `OdooAccessException` - Access rights errors
  - `OdooUserException` - Business logic errors
  - `OdooWarningException` - Odoo warnings
  - `OdooMissingException` - Record not found errors
- Improved error message extraction and parsing
- Added detailed error context support

#### Advanced Operations
- Added `getFields()` method for retrieving model field metadata
- Implemented `readGroup()` for data aggregation and grouping
- Enhanced `callKw()` for custom method execution

#### Documentation
- Created comprehensive `FEATURES_EXAMPLES.md` with usage examples
- Updated `README.md` with new features section
- Added quick start examples for common use cases
- Documented all new APIs and methods

### Changed
- Updated BridgeCore client to support all new Odoo 18 features
- Enhanced context management for better multi-company support
- Improved error handling with Odoo-specific exceptions

### Technical Improvements
- Better separation of concerns with dedicated services
- Enhanced type safety with strongly-typed events
- Improved code documentation and examples
- Better error messages and debugging support

## [1.0.0] - Previous Release

### Features
- Clean Architecture implementation
- BridgeCore Flutter SDK integration
- Offline-first architecture with sync
- Riverpod state management
- Material 3 design system
- RTL support (Arabic/English)
- Authentication flow
- Dashboard with KPIs
- Real-time notifications
- WebSocket support
- Multi-layer cache management
- Background sync
- Biometric authentication
- File management
- Search functionality
- Settings screen

---

## Migration Guide

If you're upgrading from a previous version, here's what you need to know:

### Using New Action Methods

Replace custom method calls with dedicated action methods:

**Before:**
```dart
await client.callKw(
  model: 'sale.order',
  method: 'action_confirm',
  args: [orderId],
);
```

**After:**
```dart
await client.validate(
  model: 'sale.order',
  ids: [orderId],
);
```

### Implementing Event Bus

Instead of manual callbacks, use the Event Bus:

**Before:**
```dart
// Manual callback passing
void onOrderCreated(int orderId) {
  // Refresh UI
}
```

**After:**
```dart
// Event-based communication
final eventBus = EventBusService();

// Emit
eventBus.emit(BusEvent.recordCreated(
  model: 'sale.order',
  recordId: orderId,
));

// Listen
eventBus.onModel('sale.order').listen((event) {
  // Refresh UI
});
```

### Enhanced Error Handling

Use the new Odoo error handler:

**Before:**
```dart
try {
  await operation();
} catch (e) {
  print('Error: $e');
}
```

**After:**
```dart
try {
  await operation();
} catch (e) {
  final failure = OdooErrorHandler.handleBridgeCoreException(e);
  if (failure is ValidationFailure) {
    // Handle validation error
  } else if (failure is AuthFailure) {
    // Handle auth error
  }
}
```

---

## Roadmap

### Upcoming Features
- [ ] Enhanced webhook support
- [ ] More trigger types and conditions
- [ ] Event replay and history
- [ ] Performance monitoring
- [ ] Advanced caching strategies
- [ ] Offline conflict resolution UI
- [ ] Multi-tenant support
- [ ] Advanced analytics

---

## Credits

This project is built on top of:
- [BridgeCore Flutter SDK](https://github.com/geniustep/bridgecore_flutter) by GeniusStep
- Flutter and Dart by Google
- Various open-source packages (see pubspec.yaml)

Special thanks to the BridgeCore team for the excellent Odoo integration SDK.
