import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// Shared DioClient provider (auto-attaches Odoo session cookie on each request).
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});
