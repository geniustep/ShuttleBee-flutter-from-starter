# BridgeCore Flutter Starter

Enterprise-grade Flutter starter project with complete Odoo integration via BridgeCore SDK v3.0.0.

## ✨ Features

### Core Features
- **Clean Architecture** - Well-organized codebase following Clean Architecture principles
- **BridgeCore Integration** - Full Odoo ERP integration using BridgeCore Flutter SDK v3.0.0
- **Offline-First** - Built-in offline support with advanced sync capabilities
- **State Management** - Riverpod for scalable state management
- **Modern UI** - Material 3 design with beautiful custom theme
- **RTL Support** - Full Arabic and English localization
- **Authentication** - Complete login flow with session management
- **Dashboard** - KPIs and charts for business insights

### 🆕 Full BridgeCore SDK Integration

This starter now includes **complete integration** with all BridgeCore SDK features:

#### 📡 Smart Sync (v2)
- **Offline Sync** - Push/pull changes with conflict resolution
- **Smart Sync** - Efficient sync with only changed records
- **Periodic Update Check** - Automatic background sync
- **Webhook Events** - Real-time update notifications

#### 🎯 Server-Side Triggers
- **Create Triggers** - Notification, email, webhook, Odoo method triggers
- **Manage Triggers** - Enable/disable, update, delete triggers
- **Execute Manually** - Test triggers with specific records
- **View History** - Track trigger execution history
- **Pre-built Templates** - New order, customer, low stock triggers

#### 🔔 Notifications API
- **List Notifications** - Get notifications from BridgeCore API
- **Mark as Read** - Single, multiple, or all notifications
- **Preferences** - Manage notification preferences
- **Device Registration** - Register devices for push notifications
- **FCM Integration** - Firebase Cloud Messaging support

#### 🔄 Event Bus Bridge
- **Unified Events** - Bridge between local and BridgeCore event bus
- **Auto Translation** - Automatic event type mapping
- **Bidirectional** - Forward events both ways
- **Statistics** - Track event flow

### Odoo 18 Features
- **🎯 Action Methods** - Validate, approve, reject, assign, unlock, done
- **🚀 Event Bus System** - Application-wide event system with 40+ event types
- **🔧 Trigger System** - Automated actions based on events
- **🏢 Multi-Company Support** - Company switching and access control
- **⚠️ Enhanced Error Handling** - Odoo 18-specific exceptions
- **📊 Advanced Operations** - Read group, get fields, custom method calls

## 🚀 Getting Started

### Prerequisites

- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0
- An Odoo server with BridgeCore module installed

### Installation

1. Clone the repository:
```bash
git clone https://github.com/geniustep/bridgecore_flutter_starter.git
cd bridgecore_flutter_starter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your Odoo server details
```

4. Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Run the app:
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app widget
├── bootstrap/                # App initialization
├── core/
│   ├── bridgecore_integration/  # 🆕 Full BridgeCore integration
│   │   ├── client/              # BridgeCore client wrapper
│   │   └── services/            # 🆕 SDK service integrations
│   │       ├── bridgecore_sync_service.dart
│   │       ├── bridgecore_trigger_service.dart
│   │       ├── bridgecore_notification_service.dart
│   │       ├── event_bus_bridge.dart
│   │       └── services.dart
│   ├── config/              # Configuration files
│   ├── constants/           # App constants
│   ├── theme/               # Theme system
│   ├── routing/             # GoRouter setup
│   ├── network/             # Network layer
│   ├── storage/             # Local storage
│   ├── services/            # Local services
│   ├── odoo_models/         # Odoo model classes
│   ├── error_handling/      # Error handling
│   └── utils/               # Utilities
├── shared/
│   ├── widgets/             # Reusable widgets
│   ├── models/              # Shared models
│   └── providers/           # 🆕 Global providers (including BridgeCore)
├── features/
│   ├── splash/              # Splash screen
│   ├── auth/                # Authentication
│   ├── home/                # Home & Dashboard
│   ├── settings/            # Settings
│   ├── notifications/       # Notifications
│   ├── search/              # Global search
│   └── offline_manager/     # Offline management
└── l10n/                    # Localization
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
ODOO_URL=https://your-odoo-server.com
ODOO_DATABASE=your_database
APP_NAME=My App
APP_ENV=development
DEBUG_MODE=true
```

## 📚 Usage Examples

### Initialize BridgeCore Services After Login

```dart
import 'package:bridgecore_flutter_starter/bootstrap/app_initializer.dart';

// After successful login
final session = await BridgeCore.instance.auth.login(
  email: 'user@company.com',
  password: 'password',
);

// Initialize all BridgeCore services
await AppInitializer.initializeBridgeCoreServices(
  userId: session.user.odooUserId!,
  deviceId: await getDeviceId(),
  appType: 'sales_app',
);
```

### Using Smart Sync

```dart
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';

final syncService = BridgeCoreSyncService();

// Check for updates
if (await syncService.hasUpdates()) {
  // Pull updates using smart sync
  final result = await syncService.smartPull();
  print('Pulled ${result.newEventsCount} new events');
}

// Push local changes
final pushResult = await syncService.pushLocalChanges(
  changes: {
    'sale.order': [
      {'id': 1, 'state': 'confirmed'},
    ],
  },
);

// Full sync cycle
final fullResult = await syncService.fullSync(
  localChanges: localChanges,
  models: ['sale.order', 'res.partner'],
);
```

### Creating Server-Side Triggers

```dart
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';

final triggerService = BridgeCoreTriggerService();

// Create notification trigger for new orders
final trigger = await triggerService.createNotificationTrigger(
  name: 'New Order Alert',
  model: 'sale.order',
  event: TriggerEvent.onCreate,
  notificationTitle: 'New Order Received',
  notificationMessage: 'Order {{record.name}} has been created',
  userIds: [1, 2, 3],
);

// Create webhook trigger
final webhookTrigger = await triggerService.createWebhookTrigger(
  name: 'Order Webhook',
  model: 'sale.order',
  event: TriggerEvent.onUpdate,
  webhookUrl: 'https://your-api.com/webhook',
  condition: [['state', '=', 'sale']],
);

// Execute trigger manually
final result = await triggerService.executeTrigger(
  trigger.id,
  recordIds: [1, 2, 3],
);
```

### Managing Notifications

```dart
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';

final notificationService = BridgeCoreNotificationService();

// Get unread notifications
final unread = await notificationService.getUnreadNotifications();
print('Unread: ${unread.unreadCount}');

// Mark as read
await notificationService.markAsRead(notificationId);
await notificationService.markAllAsRead();

// Update preferences
await notificationService.updatePreferences(
  enablePush: true,
  enableEmail: false,
  quietHoursEnabled: true,
  quietHoursStart: '22:00',
  quietHoursEnd: '08:00',
);

// Register device for push notifications
await notificationService.registerCurrentDevice(
  deviceName: 'My Phone',
);
```

### Using Event Bus Bridge

```dart
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/services/services.dart';

final eventBridge = EventBusBridge();

// Listen to sync events
eventBridge.onSyncEvents.listen((event) {
  print('Sync event: ${event.type}');
});

// Listen to record events for specific model
eventBridge.onModelEvents('sale.order').listen((event) {
  print('Order event: ${event.type} - ${event.recordId}');
});

// Listen to BridgeCore events
eventBridge.onBridgeCoreEvent('odoo.record_created').listen((event) {
  print('Record created: ${event.data}');
});

// Emit to both event buses
eventBridge.emitBoth(
  localType: EventType.recordCreated,
  bridgeCoreType: 'odoo.record_created',
  model: 'sale.order',
  recordId: 123,
  data: {'name': 'SO001'},
);
```

### Using Riverpod Providers

```dart
import 'package:bridgecore_flutter_starter/shared/providers/global_providers.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sync status
    final syncStatus = ref.watch(syncStatusProvider);
    
    // Watch unread notifications
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    
    // Check for updates
    final hasUpdates = ref.watch(hasUpdatesProvider);
    
    // Get sync health
    final health = ref.watch(syncHealthProvider);
    
    return Column(
      children: [
        if (syncStatus.when(
          data: (isSyncing) => isSyncing,
          loading: () => false,
          error: (_, __) => false,
        ))
          const LinearProgressIndicator(),
        
        Badge(
          label: Text('${unreadCount.value ?? 0}'),
          child: const Icon(Icons.notifications),
        ),
      ],
    );
  }
}
```

### Using Action Methods

```dart
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/client/bridgecore_client.dart';

// Validate a sale order
await client.validate(model: 'sale.order', ids: [orderId]);

// Approve a purchase order
await client.approve(model: 'purchase.order', ids: [poId]);

// Assign task to user
await client.assign(model: 'project.task', ids: [taskId], userId: userId);
```

## 📦 Dependencies

### Core
- **bridgecore_flutter** - Odoo integration SDK
- **flutter_riverpod** - State management
- **go_router** - Navigation
- **dio** - HTTP client

### Storage
- **hive_flutter** - Local database
- **flutter_secure_storage** - Secure storage
- **shared_preferences** - Simple key-value storage

### UI
- **fl_chart** - Charts
- **shimmer** - Loading effects
- **flutter_animate** - Animations
- **lottie** - Lottie animations

### Firebase
- **firebase_core** - Firebase core
- **firebase_messaging** - Push notifications
- **firebase_crashlytics** - Crash reporting
- **firebase_analytics** - Analytics

### Others
- **connectivity_plus** - Network connectivity
- **workmanager** - Background tasks
- **uuid** - UUID generation

## 🏗️ Architecture

This project follows Clean Architecture with Feature-First organization:

```
Feature/
├── data/           # Data layer (repositories impl, data sources)
├── domain/         # Domain layer (entities, repositories, use cases)
└── presentation/   # Presentation layer (screens, widgets, providers)
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support, please contact [support@geniustep.com](mailto:support@geniustep.com) or open an issue on GitHub.

---

**Version:** 2.0.0  
**BridgeCore SDK:** v3.0.0  
**Last Updated:** 2025-11-28
