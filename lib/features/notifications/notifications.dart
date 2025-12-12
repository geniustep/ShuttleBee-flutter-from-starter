/// 🔔 ShuttleBee Notifications Module
/// وحدة الإشعارات - تدعم WhatsApp, SMS, Push, Email
///
/// الاستخدام:
/// ```dart
/// import 'package:bridgecore_flutter_starter/features/notifications/notifications.dart';
/// ```

// Data Layer
export 'data/datasources/notification_remote_data_source.dart';
export 'data/repositories/notification_repository.dart';
export 'data/services/shuttle_notification_api_service.dart';

// Domain Layer
export 'domain/entities/shuttle_notification.dart';

// Presentation Layer
export 'presentation/providers/notification_providers.dart';
export 'presentation/widgets/notification_action_buttons.dart';
export 'presentation/widgets/notification_item.dart';

