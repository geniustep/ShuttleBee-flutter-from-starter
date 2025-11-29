# BridgeCore Flutter Starter - Implementation Guide

## 🎯 Overview

This guide documents all 18 enhancements implemented in the BridgeCore Flutter Starter project.

## ✅ Implemented Features

### 1. Complete Data Layer (Repositories, Data Sources, Use Cases)

**Location**: `lib/core/data/`, `lib/features/*/data/`

**Features**:
- Base repository with error handling
- Remote data source with BridgeCore integration
- Local data source with Hive
- Offline queue management
- Use cases with Either pattern

**Key Files**:
- `lib/core/data/repositories/base_repository.dart`
- `lib/core/data/datasources/remote_data_source.dart`
- `lib/core/data/datasources/local_data_source.dart`
- `lib/core/error/failures.dart`

**Usage**:
```dart
final repository = AuthRepositoryImpl(
  remoteDataSource: AuthRemoteDataSource(),
  cacheDataSource: CacheDataSource(),
);

final result = await repository.login(
  email: email,
  password: password,
);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (session) => print('Success: ${session.accessToken}'),
);
```

---

### 2. BridgeCore v2.1.0 Features

**Location**: `lib/core/services/context_manager.dart`

**Features**:
- Context Manager for language, timezone, and company
- Action methods (validate, approve, reject, etc.)
- Custom method handler
- Advanced search with 33+ operations

**Usage**:
```dart
final contextManager = OdooContextManager();
await contextManager.initialize();
await contextManager.setLanguage('ar_001');
await contextManager.setCompany(companyId);

final context = contextManager.getContext();
```

---

### 3. Offline-First Architecture

**Location**: `lib/core/services/sync_manager.dart`

**Features**:
- Sync Manager with queue
- Conflict Resolution strategies
- Automatic background sync
- Connection monitoring

**Usage**:
```dart
final syncManager = SyncManager();
await syncManager.initialize();

// Add operation to queue
await syncManager.addOperation(
  type: 'create',
  model: 'sale.order',
  data: {...},
);

// Sync when online
await syncManager.syncPendingOperations();
```

---

### 4. Real Notifications System

**Location**: `lib/core/services/notification_service.dart`

**Features**:
- Firebase Cloud Messaging
- Local Notifications
- Background handlers
- Topic subscriptions

**Usage**:
```dart
final notificationService = NotificationService();
await notificationService.initialize();

// Show notification
await notificationService.showNotification(
  id: 1,
  title: 'New Order',
  body: 'You have a new order',
);

// Subscribe to topic
await notificationService.subscribeToTopic('orders');
```

---

### 5. Enhanced Dashboard with Real Data

**Location**: `lib/features/dashboard/`

**Features**:
- Dynamic KPIs from Odoo
- Interactive charts
- Sales overview
- Orders by status
- Real-time trends

**Usage**:
```dart
final repository = DashboardRepositoryImpl(
  remoteDataSource: OdooRemoteDataSource(),
  cacheManager: CacheManager(),
);

final kpis = await repository.getKPIs();
final salesChart = await repository.getSalesOverview(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);
```

---

### 6. RBAC & Audit Trail

**Location**: `lib/core/services/permission_service.dart`

**Features**:
- Role-based access control
- Permission checks
- Audit logging
- User activity tracking

**Usage**:
```dart
final permissionService = PermissionService();
await permissionService.initialize(user);

// Check permission
if (permissionService.hasPermission('read_sales')) {
  // Access allowed
}

// Log action
await AuditTrailService().log(
  action: 'create',
  resource: 'sale.order',
  resourceId: '123',
);
```

---

### 7. UX/UI Improvements

**Location**: `lib/features/onboarding/`, `lib/core/services/tour_service.dart`

**Features**:
- Onboarding screens with Lottie
- Interactive tour guide
- Tutorial coach marks
- First-time user experience

**Usage**:
```dart
// Show onboarding
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => OnboardingScreen()),
);

// Show tour
final tourService = TourService();
await tourService.showHomeTour(
  context: context,
  keys: [drawerKey, dashboardKey, syncKey],
);
```

---

### 8. Error Tracking & Monitoring

**Location**: `lib/core/services/error_tracking_service.dart`

**Features**:
- Sentry integration
- Firebase Crashlytics
- Performance monitoring
- Custom error reporting

**Usage**:
```dart
final errorTracking = ErrorTrackingService();
await errorTracking.initialize(
  sentryDsn: 'YOUR_DSN',
  environment: 'production',
);

// Record error
errorTracking.recordError(
  error,
  stackTrace,
  extras: {'user_id': userId},
);

// Track performance
final trace = await PerformanceMonitoringService().startTrace('api_call');
// ... operation
await PerformanceMonitoringService().stopTrace(trace);
```

---

### 9. File Management

**Location**: `lib/core/services/file_service.dart`

**Features**:
- Image picker with cropping
- File upload/download
- Camera integration
- Document viewer
- Compression

**Usage**:
```dart
final fileService = FileService();

// Pick and crop image
final image = await fileService.pickImage(source: ImageSource.gallery);
if (image != null) {
  final cropped = await fileService.cropImage(imageFile: image);
  final compressed = await fileService.compressImage(imageFile: cropped!);
}

// Pick file
final file = await fileService.pickFile(type: FileType.pdf);
```

---

### 10. Advanced Search

**Location**: `lib/core/services/search_service.dart`

**Features**:
- Global search across models
- Advanced filters
- Voice search
- Recent searches
- Custom domains

**Usage**:
```dart
final searchService = SearchService();

// Global search
final results = await searchService.globalSearch(
  query: 'John',
  models: ['res.partner', 'sale.order'],
);

// Voice search
final voiceSearch = VoiceSearchService();
await voiceSearch.startListening(
  onResult: (text) => print('You said: $text'),
);
```

---

### 11. Multi-Company Support

**Location**: `lib/core/services/multi_company_service.dart`

**Features**:
- Company switcher
- Company-specific data
- Context propagation
- Company filtering

**Usage**:
```dart
final multiCompany = MultiCompanyService();
await multiCompany.initialize(companyIds, currentCompanyId);

// Switch company
await multiCompany.switchCompany(newCompanyId);

// Get company-specific data
final data = await multiCompany.getCompanyData(
  model: 'sale.order',
);
```

---

### 12. Forms Builder

**Location**: `lib/core/services/forms_builder_service.dart`

**Features**:
- Dynamic forms from Odoo
- Field validation
- Conditional fields
- Auto-save

**Usage**:
```dart
final formsBuilder = FormsBuilderService();

// Load form definition
final formDef = await formsBuilder.loadFormDefinition(
  model: 'sale.order',
);

// Build form widget
final formWidget = formsBuilder.buildForm(
  definition: formDef!,
  formKey: formKey,
  onSubmit: (values) async {
    await formsBuilder.saveForm(
      model: 'sale.order',
      values: values,
    );
  },
);
```

---

### 13. Testing & Quality

**Location**: `test/`

**Features**:
- Unit tests
- Widget tests
- Integration tests
- Code coverage

**Run Tests**:
```bash
flutter test --coverage
flutter test test/core/services/cache_manager_test.dart
```

---

### 14. CI/CD

**Location**: `.github/workflows/`

**Features**:
- Automated testing on push
- Build APK/IPA
- Code analysis
- Deployment to stores

**Workflows**:
- `ci.yml`: Run on every push/PR
- `deploy.yml`: Run on version tags

---

### 15. Real-time Updates

**Location**: `lib/core/services/websocket_service.dart`

**Features**:
- WebSocket integration
- Socket.IO support
- Channel subscriptions
- Live data updates

**Usage**:
```dart
final ws = WebSocketService();
await ws.connect(serverUrl: 'wss://your-server.com');

// Subscribe to updates
final realtimeService = RealtimeUpdatesService();
final stream = realtimeService.subscribeToModel('sale.order');

stream.listen((data) {
  print('New update: $data');
});
```

---

### 16. Biometric Authentication

**Location**: `lib/core/services/biometric_service.dart`

**Features**:
- Fingerprint/Face ID
- Device support check
- Fallback authentication

**Usage**:
```dart
final biometric = BiometricService();

// Check availability
final available = await biometric.isAvailable();

// Authenticate
final authenticated = await biometric.authenticate(
  localizedReason: 'Please authenticate to continue',
);
```

---

### 17. Advanced Caching

**Location**: `lib/core/cache/cache_manager.dart`

**Features**:
- Multi-layer cache (Memory + Disk)
- LRU eviction
- TTL support
- Smart prefetching

**Usage**:
```dart
final cache = CacheManager();

// Set with TTL
await cache.set(
  'user_data',
  userData,
  memoryTTL: Duration(minutes: 5),
  diskTTL: Duration(hours: 1),
);

// Get
final data = await cache.get('user_data');

// Prefetch
await cache.prefetch('products', () async {
  return await fetchProducts();
});
```

---

### 18. Enhanced Localization

**Location**: `lib/l10n/`

**Features**:
- Multiple languages (EN, AR, FR, ES)
- RTL support
- Currency formatting
- Date/time localization

**Supported Languages**:
- English (en)
- Arabic (ar) with RTL
- French (fr)
- Spanish (es)

**Usage**:
```dart
// Access translations
Text(AppLocalizations.of(context)!.login)

// Change language
await PrefsStorageService.instance.write(
  key: 'language',
  value: 'ar',
);
```

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run App
```bash
flutter run
```

### 4. Run Tests
```bash
flutter test --coverage
```

---

## 📦 Package Dependencies

All required packages have been added to `pubspec.yaml`:

- **State Management**: flutter_riverpod, riverpod_annotation
- **Backend**: bridgecore_flutter v2.1.0
- **Storage**: hive, shared_preferences, flutter_secure_storage
- **Notifications**: firebase_messaging, flutter_local_notifications
- **Error Tracking**: sentry_flutter, firebase_crashlytics
- **File Management**: image_picker, file_picker, image_cropper
- **Biometric**: local_auth
- **Search**: speech_to_text
- **Real-time**: socket_io_client, web_socket_channel
- **UI**: introduction_screen, tutorial_coach_mark, lottie, rive
- **Testing**: mocktail, golden_toolkit

---

## 🔧 Configuration

### Firebase Setup
1. Add `google-services.json` (Android)
2. Add `GoogleService-Info.plist` (iOS)
3. Initialize in `main.dart`

### Sentry Setup
1. Get DSN from Sentry.io
2. Add to environment variables
3. Initialize in error tracking service

### Environment Variables
Create `.env` file:
```
ODOO_URL=https://your-odoo-instance.com
SENTRY_DSN=your-sentry-dsn
```

---

## 📝 Notes

- All services are singletons
- Use dependency injection where possible
- Follow clean architecture principles
- Write tests for new features
- Update documentation

---

## 🎉 All 18 Features Completed!

This project now includes all modern Flutter best practices and integrations with BridgeCore/Odoo ERP.
