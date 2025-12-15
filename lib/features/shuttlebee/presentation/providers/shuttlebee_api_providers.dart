import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../data/services/shuttlebee_api_service.dart';

final shuttleBeeApiServiceProvider = Provider<ShuttleBeeApiService>((ref) {
  // Use a dedicated base URL for ShuttleBee REST endpoints.
  // This allows BridgeCore (JSON-RPC) to stay on ODOO_URL while REST can use SHUTTLEBEE_API_URL.
  final dioClient = DioClient(
    baseUrl: EnvConfig.shuttleBeeApiBaseUrl,
    sessionStorageKey: StorageKeys.shuttleBeeSessionId,
  );
  return ShuttleBeeApiService(dio: dioClient.dio);
});
