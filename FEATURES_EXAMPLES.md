# BridgeCore Flutter Starter - New Features Examples

## Overview

This document provides examples for the new features added based on BridgeCore Flutter SDK v3.0.0 improvements.

## Table of Contents

1. [Action Methods (Odoo 18)](#action-methods)
2. [Event Bus System](#event-bus-system)
3. [Enhanced Error Handling](#enhanced-error-handling)
4. [Multi-Company Support](#multi-company-support)
5. [Advanced Operations](#advanced-operations)

---

## Action Methods (Odoo 18)

The BridgeCore client now supports Odoo 18 action methods for common workflow operations.

### 1. Validate Records

Confirm/validate records (e.g., sales orders, invoices):

```dart
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/client/bridgecore_client.dart';

final client = BridgecoreClient(baseUrl);

// Validate a sale order
try {
  final success = await client.validate(
    model: 'sale.order',
    ids: [orderId],
  );

  if (success) {
    print('Order validated successfully');
  }
} catch (e) {
  print('Validation failed: $e');
}
```

### 2. Approve Records

Approve records that require approval:

```dart
// Approve purchase order
await client.approve(
  model: 'purchase.order',
  ids: [poId],
);
```

### 3. Reject Records

Reject records:

```dart
// Reject leave request
await client.reject(
  model: 'hr.leave',
  ids: [leaveId],
);
```

### 4. Mark as Done

Mark tasks or operations as done:

```dart
// Mark task as done
await client.done(
  model: 'project.task',
  ids: [taskId],
);
```

### 5. Assign to User

Assign records to specific users:

```dart
// Assign task to user
await client.assign(
  model: 'project.task',
  ids: [taskId],
  userId: assigneeUserId,
);
```

### 6. Unlock Records

Unlock locked records:

```dart
// Unlock invoice
await client.unlock(
  model: 'account.move',
  ids: [invoiceId],
);
```

### 7. Execute Button Actions

Execute custom button actions:

```dart
// Execute custom button
final result = await client.executeButtonAction(
  model: 'sale.order',
  ids: [orderId],
  buttonName: 'action_send_email',
);
```

---

## Event Bus System

The Event Bus allows components to communicate via events without tight coupling.

### Basic Event Emission

```dart
import 'package:bridgecore_flutter_starter/core/services/event_bus_service.dart';

final eventBus = EventBusService();

// Emit record created event
eventBus.emit(BusEvent.recordCreated(
  model: 'sale.order',
  recordId: orderId,
  data: {'name': 'SO001'},
));

// Emit record updated event
eventBus.emit(BusEvent.recordUpdated(
  model: 'sale.order',
  recordId: orderId,
  data: {'state': 'confirmed'},
));

// Emit custom event
eventBus.emit(BusEvent.custom(
  eventName: 'payment_received',
  data: {'amount': 1000.0, 'order_id': orderId},
));
```

### Listen to Events

```dart
// Listen to all events
eventBus.events.listen((event) {
  print('Event received: ${event.type} for ${event.model}');
});

// Listen to specific event type
eventBus.on(EventType.recordCreated).listen((event) {
  print('Record created: ${event.model} #${event.recordId}');
});

// Listen to events for specific model
eventBus.onModel('sale.order').listen((event) {
  print('Sale order event: ${event.type}');
  // Refresh UI or cache
});

// Listen to custom events
eventBus.onCustom('payment_received').listen((event) {
  print('Payment received: ${event.data}');
});
```

### Trigger System

Create automated actions based on events:

```dart
import 'package:bridgecore_flutter_starter/core/services/event_bus_service.dart';

final triggerService = TriggerService();
triggerService.initialize();

// Register a trigger
triggerService.registerTrigger(
  EventTrigger(
    id: 'refresh_on_order_create',
    condition: TriggerCondition(
      eventType: EventType.recordCreated,
      model: 'sale.order',
    ),
    action: (event) async {
      // Refresh orders list
      print('Refreshing orders list...');
      // await refreshOrdersList();
    },
  ),
);

// Register trigger with custom condition
triggerService.registerTrigger(
  EventTrigger(
    id: 'notify_high_value_order',
    condition: TriggerCondition(
      eventType: EventType.recordCreated,
      model: 'sale.order',
      customCondition: (event) {
        final amount = event.data?['amount_total'] as double? ?? 0;
        return amount > 10000;
      },
    ),
    action: (event) async {
      // Send notification
      print('High value order created!');
    },
  ),
);
```

---

## Enhanced Error Handling

Improved error handling with Odoo 18 specific exceptions.

### Using Odoo Error Handler

```dart
import 'package:bridgecore_flutter_starter/core/error_handling/odoo_error_handler.dart';
import 'package:bridgecore_flutter_starter/core/error_handling/failures.dart';

try {
  await client.validate(model: 'sale.order', ids: [orderId]);
} catch (e) {
  final failure = OdooErrorHandler.handleBridgeCoreException(e);

  if (failure is AuthFailure) {
    print('Authentication error: ${failure.message}');
    // Navigate to login
  } else if (failure is ValidationFailure) {
    print('Validation error: ${failure.message}');
    // Show error to user
  } else if (failure is ServerFailure) {
    print('Server error: ${failure.message}');
  }
}
```

### Handling Specific Odoo Exceptions

```dart
import 'package:bridgecore_flutter_starter/core/error_handling/exceptions.dart';

try {
  await client.create(model: 'res.partner', values: {...});
} catch (e) {
  if (e is OdooValidationException) {
    print('Validation failed: ${e.message}');
    print('Field errors: ${e.fieldErrors}');
  } else if (e is OdooAccessException) {
    print('Access denied for ${e.model} - ${e.operation}');
  } else if (e is OdooUserException) {
    print('Business logic error: ${e.message}');
  }
}
```

---

## Multi-Company Support

Enhanced Context Manager with multi-company features.

### Set User Context

```dart
import 'package:bridgecore_flutter_starter/core/services/context_manager.dart';

final contextManager = OdooContextManager();

// Initialize from user data
await contextManager.setUserContext(
  userId: 1,
  companyId: 1,
  companyIds: [1, 2, 3],
  language: 'ar_001',
  timezone: 'Africa/Cairo',
);
```

### Switch Companies

```dart
// Switch to another company
try {
  await contextManager.switchCompany(2);
  print('Switched to company 2');
} catch (e) {
  print('Cannot switch: $e');
}

// Check access
if (contextManager.hasAccessToCompany(3)) {
  print('User has access to company 3');
}

// Get active companies
final companies = contextManager.getActiveCompanies();
print('Active companies: $companies');
```

### Use Context in Operations

```dart
// Get context for current company
final context = contextManager.getContext();

await client.searchRead(
  model: 'sale.order',
  domain: [],
  fields: ['name', 'partner_id', 'amount_total'],
  context: context, // Pass context
);

// Get context for specific company
final company2Context = contextManager.getContextWithCompany(2);

// Multi-company context
final multiCompanyContext = contextManager.getMultiCompanyContext(
  companies: [1, 2],
);
```

---

## Advanced Operations

### Get Fields Metadata

```dart
// Get field definitions for a model
final fields = await client.getFields(
  model: 'sale.order',
  attributes: ['string', 'type', 'required', 'readonly'],
);

print('Fields: $fields');
```

### Read Group (Aggregation)

```dart
// Get sales grouped by state
final groups = await client.readGroup(
  model: 'sale.order',
  domain: [],
  fields: ['state', 'amount_total'],
  groupBy: ['state'],
);

for (final group in groups) {
  print('State: ${group['state']}, Total: ${group['amount_total']}');
}

// Group by month
final monthlyGroups = await client.readGroup(
  model: 'sale.order',
  domain: [['date_order', '>=', '2025-01-01']],
  fields: ['date_order', 'amount_total'],
  groupBy: ['date_order:month'],
);
```

### Custom Method Calls

```dart
// Call custom model method
final result = await client.callKw(
  model: 'sale.order',
  method: 'action_confirm',
  args: [orderId],
  kwargs: {'context': context},
);
```

---

## Integration Example: Complete Workflow

Here's a complete example combining multiple features:

```dart
import 'package:flutter/material.dart';
import 'package:bridgecore_flutter_starter/core/bridgecore_integration/client/bridgecore_client.dart';
import 'package:bridgecore_flutter_starter/core/services/event_bus_service.dart';
import 'package:bridgecore_flutter_starter/core/services/context_manager.dart';
import 'package:bridgecore_flutter_starter/core/error_handling/odoo_error_handler.dart';

class SaleOrderService {
  final BridgecoreClient client;
  final EventBusService eventBus;
  final OdooContextManager contextManager;

  SaleOrderService({
    required this.client,
    required this.eventBus,
    required this.contextManager,
  });

  /// Create and validate a sale order
  Future<int> createAndValidateOrder(Map<String, dynamic> values) async {
    try {
      // Get context
      final context = contextManager.getContext();

      // Create order
      final orderId = await client.create(
        model: 'sale.order',
        values: values,
      );

      // Emit event
      eventBus.emit(BusEvent.recordCreated(
        model: 'sale.order',
        recordId: orderId,
        data: values,
      ));

      // Validate order
      await client.validate(
        model: 'sale.order',
        ids: [orderId],
      );

      // Emit validation event
      eventBus.emit(BusEvent.recordValidated(
        model: 'sale.order',
        recordId: orderId,
      ));

      return orderId;
    } catch (e) {
      final failure = OdooErrorHandler.handleBridgeCoreException(e);
      throw Exception('Failed to create order: ${failure.message}');
    }
  }

  /// Listen to order events
  void listenToOrderEvents(Function(BusEvent) callback) {
    eventBus.onModel('sale.order').listen(callback);
  }
}

// Usage in widget
class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late SaleOrderService orderService;

  @override
  void initState() {
    super.initState();

    // Initialize service
    orderService = SaleOrderService(
      client: BridgecoreClient('https://your-odoo.com'),
      eventBus: EventBusService(),
      contextManager: OdooContextManager(),
    );

    // Listen to events
    orderService.listenToOrderEvents((event) {
      if (event.type == EventType.recordValidated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order validated successfully!')),
        );
        // Refresh list
      }
    });
  }

  Future<void> _createOrder() async {
    try {
      final orderId = await orderService.createAndValidateOrder({
        'partner_id': 1,
        'order_line': [...],
      });

      print('Order created: $orderId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orders')),
      body: ListView(...),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOrder,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## Best Practices

1. **Always handle errors properly**: Use try-catch blocks and the enhanced error handling system.

2. **Use Event Bus for loose coupling**: Emit events when data changes instead of tight component coupling.

3. **Leverage Context Manager**: Always pass proper context with language, timezone, and company information.

4. **Implement triggers for automation**: Use the Trigger Service for automated actions based on events.

5. **Test action methods**: Ensure proper permissions before calling action methods like validate, approve, etc.

6. **Multi-company aware**: Always consider multi-company scenarios when building features.

---

## Additional Resources

- [BridgeCore Flutter SDK Documentation](https://github.com/geniustep/bridgecore_flutter)
- [Odoo 18 Documentation](https://www.odoo.com/documentation/18.0/)
- [Implementation Guide](./IMPLEMENTATION_GUIDE.md)
