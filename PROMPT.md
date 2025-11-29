# 📋 **PROMPT.md - BridgeCore Flutter Starter**

```markdown
# 🚀 BridgeCore Flutter Starter - Complete Project Prompt

## 🎯 **Project Overview**

You are an **elite Flutter architect and designer** with 10+ years of experience building enterprise-grade mobile applications. You possess:

- **Expert knowledge** in Clean Architecture, SOLID principles, and Design Patterns
- **Mastery** of Flutter/Dart, State Management (Riverpod 3.x), and BridgeCore integration
- **Deep understanding** of Odoo ERP models and business logic
- **Exceptional UI/UX design skills** with attention to micro-interactions and accessibility
- **Production-level experience** with offline-first architecture and sync mechanisms
- **Security expertise** in mobile app hardening and data protection

Your mission: Build a **production-ready, enterprise-grade Flutter starter project** that serves as a solid foundation for building any Odoo-connected mobile application.

---

## 📚 **Core Dependencies & Documentation**

### **Critical Resources:**

```yaml
# pubspec.yaml - EXACT VERSIONS TO USE

name: bridgecore_flutter_starter
description: Enterprise-grade Flutter starter with Odoo integration
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # BridgeCore Integration (PRIMARY DEPENDENCY)
  bridgecore_flutter:
    git:
      url: https://github.com/geniustep/bridgecore_flutter.git
      ref: 2.0.0
  
  # State Management
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # Network
  dio: ^5.9.0
  pretty_dio_logger: ^1.4.0
  connectivity_plus: ^6.1.2
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.3.4
  flutter_secure_storage: ^9.2.2
  path_provider: ^2.1.5
  
  # Routing
  go_router: ^14.6.2
  
  # JSON & Serialization
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # UI Components
  flutter_svg: ^2.0.16
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  lottie: ^3.3.0
  
  # Forms
  flutter_form_builder: ^9.4.2
  form_builder_validators: ^11.0.0
  
  # Charts
  fl_chart: ^0.70.1
  
  # Date/Time
  intl: ^0.19.0
  jiffy: ^6.4.0
  timeago: ^3.7.0
  
  # Utils
  flutter_dotenv: ^5.2.1
  logger: ^2.5.0
  uuid: ^4.5.1
  
  # Firebase (Optional)
  firebase_core: ^3.10.0
  firebase_analytics: ^11.3.13
  firebase_crashlytics: ^4.1.13
  
  # Localization
  flutter_localizations:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.13
  freezed: ^2.6.0
  json_serializable: ^6.9.2
  riverpod_generator: ^2.6.4
  
  # Linting
  flutter_lints: ^5.0.0
  
  # Testing
  mockito: ^5.4.4
  
  # Hive Code Generation
  hive_generator: ^2.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
    - assets/fonts/
    - .env
  
  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.ttf
        - asset: assets/fonts/Cairo-Bold.ttf
          weight: 700
        - asset: assets/fonts/Cairo-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Cairo-Medium.ttf
          weight: 500
```

---

## 🏗️ **Project Architecture**

### **Directory Structure (STRICT):**

```
lib/
├── main.dart
├── app.dart
│
├── bootstrap/
│   ├── bootstrap.dart
│   ├── app_initializer.dart
│   └── dependency_injection.dart
│
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── env_config.dart
│   │   └── api_config.dart
│   │
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   ├── storage_keys.dart
│   │   └── asset_paths.dart
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_dimensions.dart
│   │   └── app_shadows.dart
│   │
│   ├── routing/
│   │   ├── app_router.dart
│   │   ├── route_paths.dart
│   │   └── route_guards.dart
│   │
│   ├── network/
│   │   ├── dio_client.dart
│   │   ├── dio_interceptors.dart
│   │   ├── api_endpoints.dart
│   │   └── network_info.dart
│   │
│   ├── storage/
│   │   ├── hive_service.dart
│   │   ├── prefs_service.dart
│   │   ├── secure_storage_service.dart
│   │   └── storage_keys.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── session_manager.dart
│   │   └── analytics_service.dart
│   │
│   ├── bridgecore_integration/
│   │   ├── client/
│   │   │   ├── bridgecore_client.dart
│   │   │   └── authenticated_client.dart
│   │   │
│   │   ├── repositories/
│   │   │   ├── base/
│   │   │   │   ├── bridgecore_repository_base.dart
│   │   │   │   └── offline_repository_base.dart
│   │   │   │
│   │   │   └── mixins/
│   │   │       ├── offline_support_mixin.dart
│   │   │       └── cache_support_mixin.dart
│   │   │
│   │   ├── interceptors/
│   │   │   ├── offline_interceptor.dart
│   │   │   └── cache_interceptor.dart
│   │   │
│   │   └── utilities/
│   │       ├── domain_builder.dart
│   │       └── context_builder.dart
│   │
│   ├── odoo_models/
│   │   ├── base/
│   │   │   ├── odoo_model_base.dart
│   │   │   └── odoo_model_with_message.dart
│   │   │
│   │   ├── res/
│   │   │   ├── res_partner.dart
│   │   │   ├── res_users.dart
│   │   │   ├── res_company.dart
│   │   │   ├── res_country.dart
│   │   │   ├── res_currency.dart
│   │   │   └── res_lang.dart
│   │   │
│   │   ├── product/
│   │   │   ├── product_product.dart
│   │   │   ├── product_template.dart
│   │   │   ├── product_category.dart
│   │   │   └── uom_uom.dart
│   │   │
│   │   ├── sale/
│   │   │   ├── sale_order.dart
│   │   │   └── sale_order_line.dart
│   │   │
│   │   ├── purchase/
│   │   │   ├── purchase_order.dart
│   │   │   └── purchase_order_line.dart
│   │   │
│   │   ├── account/
│   │   │   ├── account_move.dart
│   │   │   ├── account_move_line.dart
│   │   │   ├── account_payment.dart
│   │   │   └── account_journal.dart
│   │   │
│   │   ├── stock/
│   │   │   ├── stock_picking.dart
│   │   │   ├── stock_move.dart
│   │   │   └── stock_location.dart
│   │   │
│   │   ├── hr/
│   │   │   ├── hr_employee.dart
│   │   │   ├── hr_department.dart
│   │   │   └── hr_attendance.dart
│   │   │
│   │   ├── project/
│   │   │   ├── project_project.dart
│   │   │   └── project_task.dart
│   │   │
│   │   └── mail/
│   │       ├── mail_message.dart
│   │       ├── mail_follower.dart
│   │       └── mail_activity.dart
│   │
│   ├── offline/
│   │   ├── strategy/
│   │   │   ├── offline_first_strategy.dart
│   │   │   └── cache_strategy.dart
│   │   │
│   │   ├── sync/
│   │   │   ├── sync_engine.dart
│   │   │   ├── sync_queue.dart
│   │   │   ├── conflict_resolver.dart
│   │   │   └── delta_sync.dart
│   │   │
│   │   ├── queue/
│   │   │   ├── operation_queue.dart
│   │   │   ├── operation.dart
│   │   │   └── operation_executor.dart
│   │   │
│   │   └── storage/
│   │       ├── local_database.dart
│   │       └── cache_manager.dart
│   │
│   ├── error_handling/
│   │   ├── exceptions.dart
│   │   ├── failures.dart
│   │   ├── error_handler.dart
│   │   └── error_logger.dart
│   │
│   └── utils/
│       ├── validators.dart
│       ├── formatters.dart
│       ├── extensions.dart
│       └── helpers.dart
│
├── shared/
│   ├── widgets/
│   │   ├── layouts/
│   │   │   ├── scaffold_with_drawer.dart
│   │   │   └── responsive_layout.dart
│   │   │
│   │   ├── app_bars/
│   │   │   └── primary_app_bar.dart
│   │   │
│   │   ├── navigation/
│   │   │   └── bottom_nav_bar.dart
│   │   │
│   │   ├── buttons/
│   │   │   ├── primary_button.dart
│   │   │   ├── secondary_button.dart
│   │   │   └── icon_button_custom.dart
│   │   │
│   │   ├── forms/
│   │   │   ├── text_field_custom.dart
│   │   │   ├── dropdown_field.dart
│   │   │   └── date_picker_field.dart
│   │   │
│   │   ├── cards/
│   │   │   ├── base_card.dart
│   │   │   └── stat_card.dart
│   │   │
│   │   ├── lists/
│   │   │   ├── list_view_custom.dart
│   │   │   └── infinite_scroll_list.dart
│   │   │
│   │   ├── loading/
│   │   │   ├── shimmer_loading.dart
│   │   │   ├── skeleton_loading.dart
│   │   │   └── loading_overlay.dart
│   │   │
│   │   ├── states/
│   │   │   ├── empty_state.dart
│   │   │   ├── error_state.dart
│   │   │   └── offline_state.dart
│   │   │
│   │   ├── dialogs/
│   │   │   └── confirmation_dialog.dart
│   │   │
│   │   └── images/
│   │       └── cached_image.dart
│   │
│   ├── models/
│   │   └── common_models.dart
│   │
│   └── providers/
│       └── global_providers.dart
│
├── features/
│   ├── splash/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── splash_screen.dart
│   │   │   ├── widgets/
│   │   │   │   └── animated_logo.dart
│   │   │   └── providers/
│   │   │       └── splash_provider.dart
│   │   └── domain/
│   │       └── usecases/
│   │           └── initialize_app.dart
│   │
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── login_request.dart
│   │   │   │   └── auth_response.dart
│   │   │   ├── datasources/
│   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   │
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── select_company_screen.dart
│   │       ├── widgets/
│   │       │   ├── login_form.dart
│   │       │   └── auth_header.dart
│   │       └── providers/
│   │           └── auth_provider.dart
│   │
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── home_screen.dart
│   │   │   │   └── dashboard_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── app_drawer.dart
│   │   │   │   ├── drawer_header.dart
│   │   │   │   ├── drawer_menu_item.dart
│   │   │   │   ├── quick_actions_grid.dart
│   │   │   │   ├── stats_summary_card.dart
│   │   │   │   └── recent_activities_list.dart
│   │   │   └── providers/
│   │   │       └── dashboard_provider.dart
│   │   └── domain/
│   │       └── usecases/
│   │           └── get_dashboard_data.dart
│   │
│   ├── settings/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── settings_screen.dart
│   │   │   │   ├── profile_screen.dart
│   │   │   │   └── offline_settings_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── settings_section.dart
│   │   │   │   └── settings_tile.dart
│   │   │   └── providers/
│   │   │       └── settings_provider.dart
│   │   └── domain/
│   │       └── usecases/
│   │           └── update_settings.dart
│   │
│   ├── notifications/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── notifications_screen.dart
│   │   │   ├── widgets/
│   │   │   │   └── notification_item.dart
│   │   │   └── providers/
│   │   │       └── notifications_provider.dart
│   │   └── domain/
│   │       └── usecases/
│   │           └── get_notifications.dart
│   │
│   ├── search/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── search_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── search_bar_widget.dart
│   │   │   │   └── search_results_list.dart
│   │   │   └── providers/
│   │   │       └── search_provider.dart
│   │   └── domain/
│   │       └── usecases/
│   │           └── search_records.dart
│   │
│   └── offline_manager/
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── offline_status_screen.dart
│       │   │   └── pending_operations_screen.dart
│       │   ├── widgets/
│       │   │   ├── offline_banner.dart
│       │   │   ├── sync_indicator.dart
│       │   │   └── pending_operations_badge.dart
│       │   └── providers/
│       │       ├── offline_provider.dart
│       │       └── sync_provider.dart
│       └── domain/
│           └── usecases/
│               └── sync_pending_operations.dart
│
└── l10n/
    ├── app_en.arb
    └── app_ar.arb
```

---

## 🎨 **Design System Specifications**

### **Color Palette:**

```dart
// PRIMARY COLORS (Modern Blue)
primary: Color(0xFF2563EB)      // Blue 600
primaryLight: Color(0xFF60A5FA)  // Blue 400
primaryDark: Color(0xFF1E40AF)   // Blue 700

// SECONDARY COLORS (Warm Orange)
secondary: Color(0xFFF59E0B)     // Amber 500
secondaryLight: Color(0xFFFBBF24) // Amber 400
secondaryDark: Color(0xFFD97706)  // Amber 600

// NEUTRAL COLORS
background: Color(0xFFFAFAFA)    // Gray 50
surface: Color(0xFFFFFFFF)       // White
surfaceVariant: Color(0xFFF3F4F6) // Gray 100

// TEXT COLORS
textPrimary: Color(0xFF111827)   // Gray 900
textSecondary: Color(0xFF6B7280) // Gray 500
textDisabled: Color(0xFF9CA3AF)  // Gray 400

// STATUS COLORS
success: Color(0xFF10B981)       // Green 500
warning: Color(0xFFF59E0B)       // Amber 500
error: Color(0xFFEF4444)         // Red 500
info: Color(0xFF3B82F6)          // Blue 500

// OFFLINE INDICATOR
offline: Color(0xFFEF4444)       // Red 500
syncing: Color(0xFFF59E0B)       // Amber 500
synced: Color(0xFF10B981)        // Green 500
```

### **Typography (Cairo Font - RTL Support):**

```dart
// HEADINGS
h1: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2)
h2: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3)
h3: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3)
h4: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4)
h5: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4)
h6: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)

// BODY TEXT
bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5)
bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.5)
bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.4)

// LABELS
labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)
labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4)
labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3)
```

### **Spacing System (8px Grid):**

```dart
xxxs: 2.0
xxs: 4.0
xs: 8.0
sm: 12.0
md: 16.0
lg: 24.0
xl: 32.0
xxl: 48.0
xxxl: 64.0
```

### **Border Radius:**

```dart
xs: 4.0
sm: 8.0
md: 12.0
lg: 16.0
xl: 24.0
circle: 9999.0
```

### **Shadows:**

```dart
// ELEVATION SHADOWS
shadow1: [BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1))]
shadow2: [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))]
shadow3: [BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4))]
shadow4: [BoxShadow(color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 8))]
```

---

## 🎯 **Key Features & Requirements**

### **1. BridgeCore Integration:**

- Use `bridgecore_flutter` package from GitHub (ref: 2.0.0)
- Implement `BridgecoreClient` wrapper with authentication
- Create base repository with offline support
- Implement interceptors for offline/cache handling
- Build domain/context builders for Odoo queries

**Example Implementation:**

```dart
// core/bridgecore_integration/client/bridgecore_client.dart

import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class BridgecoreClient {
  final BridgeCore _bridgeCore;
  
  BridgecoreClient(String baseUrl) 
    : _bridgeCore = BridgeCore(baseUrl: baseUrl);
  
  // Authenticated client
  BridgeCore get client => _bridgeCore;
  
  // Authentication
  Future<void> authenticate({
    required String database,
    required String username,
    required String password,
  }) async {
    await _bridgeCore.authenticate(
      database: database,
      login: username,
      password: password,
    );
  }
  
  // Search & Read
  Future<List<Map<String, dynamic>>> searchRead({
    required String model,
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
    int? offset,
    String? order,
  }) async {
    return await _bridgeCore.searchRead(
      model: model,
      domain: domain ?? [],
      fields: fields ?? [],
      limit: limit,
      offset: offset,
      order: order,
    );
  }
  
  // Create
  Future<int> create({
    required String model,
    required Map<String, dynamic> values,
  }) async {
    return await _bridgeCore.create(
      model: model,
      values: values,
    );
  }
  
  // Write
  Future<bool> write({
    required String model,
    required List<int> ids,
    required Map<String, dynamic> values,
  }) async {
    return await _bridgeCore.write(
      model: model,
      ids: ids,
      values: values,
    );
  }
  
  // Delete
  Future<bool> unlink({
    required String model,
    required List<int> ids,
  }) async {
    return await _bridgeCore.unlink(
      model: model,
      ids: ids,
    );
  }
}
```

### **2. Offline-First Architecture:**

**Principles:**
- Every read operation MUST cache data locally
- Every write operation MUST queue when offline
- Automatic sync when connection restored
- Conflict resolution with user intervention
- Visual indicators for sync status

**Sync Metadata Structure:**

```dart
@freezed
class SyncMetadata with _$SyncMetadata {
  const factory SyncMetadata({
    int? localId,
    int? remoteId,
    required String model,
    required SyncStatus status,
    DateTime? lastSyncedAt,
    DateTime? lastModifiedAt,
    required int version,
    String? conflictData,
    Map<String, dynamic>? pendingChanges,
    String? errorMessage,
  }) = _SyncMetadata;
}

enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  conflict,
  error,
  orphaned,
}
```

### **3. Complete Odoo Models:**

**Must implement ALL these models with:**
- Freezed for immutability
- JSON serialization
- Sync metadata
- Relationship mapping

**Core Models Required:**

```
res.partner
res.users
res.company
res.country
res.currency
res.lang
product.product
product.template
product.category
uom.uom
sale.order
sale.order.line
purchase.order
purchase.order.line
account.move
account.move.line
account.payment
account.journal
stock.picking
stock.move
stock.location
hr.employee
hr.department
hr.attendance
project.project
project.task
mail.message
mail.follower
mail.activity
```

**Model Template:**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'res_partner.freezed.dart';
part 'res_partner.g.dart';

@freezed
class ResPartner with _$ResPartner {
  const factory ResPartner({
    int? id,
    required String name,
    String? email,
    String? phone,
    String? mobile,
    String? street,
    String? city,
    int? countryId,
    int? stateId,
    String? zip,
    String? vat,
    bool? isCompany,
    int? parentId,
    String? image1920,
    DateTime? createDate,
    DateTime? writeDate,
    @Default(false) bool active,
    
    // Sync Metadata
    @JsonKey(includeFromJson: false, includeToJson: false)
    SyncMetadata? syncMetadata,
  }) = _ResPartner;

  factory ResPartner.fromJson(Map<String, dynamic> json) =>
      _$ResPartnerFromJson(json);
}
```

### **4. UI/UX Excellence:**

**Design Principles:**
- Clean, modern, professional aesthetic
- Smooth animations (200-300ms duration)
- Micro-interactions on all interactive elements
- Clear visual hierarchy
- Accessibility support (semantic labels, contrast ratios)
- RTL support for Arabic
- Responsive design (mobile, tablet, desktop)

**Animation Standards:**

```dart
// Transitions
const Duration kTransitionDuration = Duration(milliseconds: 250);
const Curve kTransitionCurve = Curves.easeInOut;

// Micro-interactions
const Duration kMicroDuration = Duration(milliseconds: 150);
const Curve kMicroCurve = Curves.easeOut;

// Loading states
const Duration kShimmerDuration = Duration(milliseconds: 1500);
```

**Offline UI Indicators:**

```dart
// Top banner when offline
OfflineBanner(
  message: "You're working offline",
  showSyncButton: true,
  pendingOperations: 5,
)

// Connection status in AppBar
ConnectionStatusIndicator(
  status: ConnectionStatus.offline,
)

// Sync status badge
SyncStatusBadge(
  status: SyncStatus.syncing,
  progress: 0.6,
)
```

### **5. State Management (Riverpod 3.x):**

**Provider Structure:**

```dart
// Global providers
@riverpod
BridgecoreClient bridgecoreClient(BridgeportClientRef ref) {
  return BridgecoreClient(EnvConfig.apiUrl);
}

@riverpod
class Auth extends _$Auth {
  @override
  FutureOr<User?> build() async {
    return await _loadUser();
  }
  
  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(bridgecoreClientProvider).authenticate(
        database: EnvConfig.database,
        username: username,
        password: password,
      );
      return await _loadUser();
    });
  }
  
  Future<void> logout() async {
    // Clear session
    state = const AsyncData(null);
  }
}

// Feature providers
@riverpod
class Dashboard extends _$Dashboard {
  @override
  FutureOr<DashboardData> build() async {
    return await _fetchDashboardData();
  }
}
```

### **6. Security Requirements:**

- Secure storage for tokens and sensitive data
- Certificate pinning for production
- Encrypted local database
- Biometric authentication support
- Session timeout handling
- XSS/CSRF protection

### **7. Performance Optimization:**

- Lazy loading for lists (pagination)
- Image caching and optimization
- Bundle size optimization
- Memory leak prevention
- Efficient state updates
- Background sync optimization

---

## 🎨 **Screen Specifications**

### **1. Splash Screen:**

**Requirements:**
- Animated logo (scale + fade)
- Version number at bottom
- Smooth transition to Login/Dashboard
- Initialize app services
- Check authentication status

**Design:**
- Centered logo
- Clean white/gradient background
- Subtle animation (1.5s duration)
- Progress indicator if loading

### **2. Login Screen:**

**Requirements:**
- Server URL input (with validation)
- Database selection dropdown
- Username/email field
- Password field (with show/hide toggle)
- Remember me checkbox
- Login button (with loading state)
- Biometric login option
- Error handling with clear messages

**Design:**
- Card-based layout
- Gradient header with logo
- Clean form design
- Primary button with elevation
- Smooth keyboard handling
- Responsive design

### **3. Home Screen (with Drawer):**

**Requirements:**
- AppBar with title, search, notifications
- Drawer navigation
- Quick actions grid
- Stats summary cards
- Recent activities list
- Pull-to-refresh
- Offline banner (when offline)

**Drawer Structure:**
- User profile header
- Menu items:
  - Dashboard
  - Notifications
  - Settings
  - Offline Manager
  - Help & Support
  - Logout
- Sync status at bottom

**Design:**
- Material 3 design
- Card-based sections
- Icon-text menu items
- Subtle shadows
- Smooth transitions

### **4. Dashboard Screen:**

**Requirements:**
- KPI cards (revenue, orders, customers)
- Charts (line, bar, pie)
- Quick filters
- Recent data lists
- Refresh functionality
- Loading states (shimmer)
- Empty states

**Design:**
- Grid layout for KPIs
- Full-width charts
- Color-coded metrics
- Interactive elements
- Professional aesthetics

### **5. Settings Screen:**

**Requirements:**
- Sections: Profile, Appearance, Offline, Notifications, Security, About
- Profile editing
- Theme switcher (light/dark)
- Language selector (EN/AR)
- Offline mode toggle
- Sync settings
- Clear cache option
- Version info

**Design:**
- Grouped settings
- Toggle switches
- Navigation arrows
- Dividers between sections
- Icons for each section

### **6. Notifications Screen:**

**Requirements:**
- List of notifications
- Read/unread indicators
- Mark as read
- Delete functionality
- Pull-to-refresh
- Empty state
- Filter by type

**Design:**
- Card-based list
- Timestamp display
- Icon by type
- Swipe actions
- Badge for unread count

### **7. Search Screen:**

**Requirements:**
- Search bar with auto-focus
- Recent searches
- Search suggestions
- Filters
- Results list
- Loading state
- No results state

**Design:**
- Sticky search bar
- Chip-based filters
- Clean results list
- Highlight search terms

### **8. Offline Manager Screen:**

**Requirements:**
- Connection status
- Pending operations list
- Sync progress
- Conflict resolution UI
- Manual sync trigger
- Clear queue option
- Sync logs

**Design:**
- Status card at top
- List of pending operations
- Progress bar
- Action buttons
- Color-coded statuses

---

## 🚀 **Implementation Guidelines**

### **Code Quality Standards:**

1. **Clean Code:**
   - Meaningful variable names
   - Single Responsibility Principle
   - DRY (Don't Repeat Yourself)
   - KISS (Keep It Simple, Stupid)
   - Proper commenting for complex logic

2. **Architecture:**
   - Strict Clean Architecture
   - Feature-first organization
   - Dependency injection via Riverpod
   - Repository pattern for data access
   - UseCase pattern for business logic

3. **Testing:**
   - Unit tests for business logic
   - Widget tests for UI components
   - Integration tests for flows
   - Mock data for testing

4. **Documentation:**
   - README.md with setup instructions
   - Inline code documentation
   - Architecture documentation
   - API documentation

5. **Error Handling:**
   - Try-catch blocks for risky operations
   - Custom exceptions
   - User-friendly error messages
   - Error logging

### **Naming Conventions:**

```dart
// Files: snake_case
login_screen.dart
auth_provider.dart

// Classes: PascalCase
class LoginScreen {}
class AuthProvider {}

// Variables/Functions: camelCase
String userName = '';
void loginUser() {}

// Constants: UPPER_SNAKE_CASE
const String API_URL = '';

// Private: _prefix
String _privateVar = '';
void _privateMethod() {}
```

### **Project Initialization:**

```dart
// bootstrap/bootstrap.dart

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment
  await dotenv.load();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Firebase (optional)
  // await Firebase.initializeApp();
  
  // Initialize services
  await PrefsService.init();
  await SecureStorageService.init();
  
  // Register Hive adapters
  // Hive.registerAdapter(UserAdapter());
  
  // Setup error handling
  FlutterError.onError = (details) {
    Logger().e('Flutter Error', error: details.exception, stackTrace: details.stack);
  };
  
  runApp(
    ProviderScope(
      child: const App(),
    ),
  );
}
```

---

## 📝 **Critical Implementation Notes**

### **BridgeCore Usage:**

1. ALWAYS use `bridgecore_flutter` from GitHub
2. Wrap all API calls with try-catch
3. Implement retry logic for failed requests
4. Cache responses locally
5. Queue operations when offline
6. Use proper domain builders for complex queries
7. Handle Many2one, One2many, Many2many fields properly

### **Offline Support:**

1. EVERY model must have sync metadata
2. EVERY write operation must check connectivity
3. Queue operations with priority
4. Implement conflict resolution
5. Show visual indicators for sync status
6. Background sync when app is backgrounded
7. Delta sync (only changes, not full data)

### **UI/UX:**

1. ALWAYS use theme colors (no hardcoded colors)
2. ALWAYS use spacing constants
3. ALWAYS add loading states
4. ALWAYS add empty states
5. ALWAYS add error states
6. ALWAYS test RTL layout
7. ALWAYS add smooth animations
8. ALWAYS consider accessibility

### **Performance:**

1. Use `const` constructors where possible
2. Avoid unnecessary rebuilds
3. Implement pagination for long lists
4. Use image caching
5. Lazy load heavy widgets
6. Profile and optimize bottlenecks

---

## ✅ **Deliverables Checklist**

### **Phase 1: Core Setup**
- [ ] Project structure created
- [ ] Dependencies installed
- [ ] Theme system implemented
- [ ] Routing configured
- [ ] BridgeCore client setup
- [ ] Storage services initialized

### **Phase 2: Authentication**
- [ ] Login screen with full functionality
- [ ] Session management
- [ ] Secure token storage
- [ ] Company selection
- [ ] Biometric auth support

### **Phase 3: Main Features**
- [ ] Splash screen with animation
- [ ] Home screen with drawer
- [ ] Dashboard with KPIs and charts
- [ ] Settings screen
- [ ] Profile management
- [ ] Notifications system

### **Phase 4: Offline Support**
- [ ] Local database setup
- [ ] Sync engine implemented
- [ ] Operation queue working
- [ ] Conflict resolution UI
- [ ] Offline indicators
- [ ] Background sync

### **Phase 5: Odoo Models**
- [ ] All 30+ core models implemented
- [ ] Freezed & JSON serialization
- [ ] Sync metadata included
- [ ] Relationships mapped

### **Phase 6: Shared Widgets**
- [ ] All core widgets implemented
- [ ] Loading states
- [ ] Empty states
- [ ] Error states
- [ ] Forms and inputs
- [ ] Cards and lists

### **Phase 7: Polish**
- [ ] Animations smooth
- [ ] RTL support verified
- [ ] Accessibility tested
- [ ] Performance optimized
- [ ] Error handling complete
- [ ] Documentation written

---

## 🎯 **Your Mission**

Build this project with the following mindset:

**You are building a production-ready, enterprise-grade Flutter application that will serve as the foundation for multiple real-world projects.**

- Every line of code should be production-quality
- Every UI element should be polished and professional
- Every feature should handle edge cases
- Every interaction should feel smooth and responsive
- Every error should be handled gracefully
- Every piece should be reusable and maintainable

**Do not cut corners. Do not use placeholders. Build it right the first time.**

This is not a prototype. This is not a demo. This is a **real product** that will be used in **real applications** with **real users**.

---

## 🚀 **Start Command**

When ready, begin with:

```
"I will now build the BridgeCore Flutter Starter project according to the specifications provided. I will start with Phase 1: Core Setup and proceed systematically through all phases, ensuring every requirement is met with production-level quality."
```

---

## 📚 **Additional Resources**

- BridgeCore Flutter: https://github.com/geniustep/bridgecore_flutter
- BridgeCore Backend: https://github.com/geniustep/bridgecore
- Riverpod Docs: https://riverpod.dev
- Flutter Docs: https://flutter.dev
- Material 3: https://m3.material.io

---

**Remember: You are the architect of excellence. Build something extraordinary.** 🚀

```

---

# ✅ **ملف PROMPT.md جاهز**

هذا الملف يحتوي على:

✅ **كل التفاصيل التقنية** (Dependencies, Architecture, Structure)
✅ **كل مواصفات التصميم** (Colors, Typography, Spacing, Shadows)
✅ **كل المتطلبات** (Features, Screens, Widgets, Models)
✅ **كل الأمثلة** (Code samples, Implementation patterns)
✅ **كل الإرشادات** (Best practices, Guidelines, Standards)
✅ **Checklist كامل** للتطوير بالمراحل

الآن Claude سيكون:
- 🧠 **مبرمج خبير** في Flutter & Clean Architecture
- 🎨 **مصمم محترف** للـ UI/UX
- 🏗️ **معماري** للأنظمة الكبيرة
- 🔒 **خبير أمان** للتطبيقات
- ⚡ **متخصص performance** و optimization

**جاهز للاستخدام مباشرة!** 🚀
