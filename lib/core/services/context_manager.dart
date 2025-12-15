import 'package:flutter/material.dart';
import 'package:bridgecore_flutter_starter/core/storage/secure_storage_service.dart';

/// Context manager for Odoo operations
/// Handles language, timezone, and company context
class OdooContextManager {
  static final OdooContextManager _instance = OdooContextManager._internal();
  factory OdooContextManager() => _instance;
  OdooContextManager._internal();

  final _storage = SecureStorageService.instance;

  String? _language;
  String? _timezone;
  int? _companyId;
  List<int>? _companyIds;
  final Map<String, dynamic> _customContext = {};

  /// Get current language code (e.g., 'ar_001', 'en_US')
  String get language => _language ?? 'en_US';

  /// Get current timezone (e.g., 'Africa/Cairo')
  String get timezone => _timezone ?? 'UTC';

  /// Get current company ID
  int? get companyId => _companyId;

  /// Get allowed company IDs
  List<int>? get companyIds => _companyIds;

  /// Get custom context
  Map<String, dynamic> get customContext => _customContext;

  /// Initialize context from storage
  Future<void> initialize() async {
    _language = await _storage.read(key: 'context_language') ?? 'en_US';
    _timezone = await _storage.read(key: 'context_timezone') ?? 'UTC';

    final companyIdStr = await _storage.read(key: 'context_company_id');
    if (companyIdStr != null) {
      _companyId = int.tryParse(companyIdStr);
    }

    final companyIdsStr = await _storage.read(key: 'context_company_ids');
    if (companyIdsStr != null) {
      _companyIds = companyIdsStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .cast<int>()
          .toList();
    }
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    await _storage.write(key: 'context_language', value: languageCode);
  }

  /// Set timezone
  Future<void> setTimezone(String tz) async {
    _timezone = tz;
    await _storage.write(key: 'context_timezone', value: tz);
  }

  /// Set company
  Future<void> setCompany(int companyId) async {
    _companyId = companyId;
    await _storage.write(
        key: 'context_company_id', value: companyId.toString());
  }

  /// Set allowed companies
  Future<void> setCompanyIds(List<int> ids) async {
    _companyIds = ids;
    await _storage.write(
      key: 'context_company_ids',
      value: ids.join(','),
    );
  }

  /// Set custom context value
  void setCustom(String key, dynamic value) {
    _customContext[key] = value;
  }

  /// Remove custom context value
  void removeCustom(String key) {
    _customContext.remove(key);
  }

  /// Get full context for Odoo operations
  Map<String, dynamic> getContext({
    Map<String, dynamic>? additionalContext,
  }) {
    final context = <String, dynamic>{
      'lang': _language,
      'tz': _timezone,
      if (_companyId != null) 'allowed_company_ids': [_companyId],
      if (_companyIds != null && _companyIds!.isNotEmpty)
        'allowed_company_ids': _companyIds,
      ..._customContext,
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    return context;
  }

  /// Get language from Flutter locale
  String getOdooLanguageCode(Locale locale) {
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    // Map Flutter locale to Odoo language codes
    if (languageCode == 'ar') {
      return countryCode != null ? 'ar_${countryCode.toUpperCase()}' : 'ar_001';
    } else if (languageCode == 'en') {
      return countryCode != null ? 'en_${countryCode.toUpperCase()}' : 'en_US';
    } else if (languageCode == 'fr') {
      return countryCode != null ? 'fr_${countryCode.toUpperCase()}' : 'fr_FR';
    } else if (languageCode == 'es') {
      return countryCode != null ? 'es_${countryCode.toUpperCase()}' : 'es_ES';
    }

    // Default fallback
    return countryCode != null
        ? '${languageCode}_${countryCode.toUpperCase()}'
        : 'en_US';
  }

  /// Clear all context
  Future<void> clear() async {
    _language = null;
    _timezone = null;
    _companyId = null;
    _companyIds = null;
    _customContext.clear();

    await _storage.delete(key: 'context_language');
    await _storage.delete(key: 'context_timezone');
    await _storage.delete(key: 'context_company_id');
    await _storage.delete(key: 'context_company_ids');
  }

  /// Set user context from user data
  Future<void> setUserContext({
    required int userId,
    required int companyId,
    required List<int> companyIds,
    String? language,
    String? timezone,
  }) async {
    await setCompany(companyId);
    await setCompanyIds(companyIds);

    if (language != null) {
      await setLanguage(language);
    }

    if (timezone != null) {
      await setTimezone(timezone);
    }

    // Store user ID for reference
    setCustom('user_id', userId);
  }

  /// Switch to another company (for multi-company support)
  Future<void> switchCompany(int companyId) async {
    if (_companyIds == null || !_companyIds!.contains(companyId)) {
      throw StateError(
          'Cannot switch to company $companyId. User does not have access.');
    }

    await setCompany(companyId);
  }

  /// Get active companies for current user
  List<int> getActiveCompanies() {
    if (_companyIds != null && _companyIds!.isNotEmpty) {
      return _companyIds!;
    }
    if (_companyId != null) {
      return [_companyId!];
    }
    return [];
  }

  /// Check if user has access to company
  bool hasAccessToCompany(int companyId) {
    return _companyIds?.contains(companyId) ?? (_companyId == companyId);
  }

  /// Get context with specific company override
  Map<String, dynamic> getContextWithCompany(
    int companyId, {
    Map<String, dynamic>? additionalContext,
  }) {
    if (!hasAccessToCompany(companyId)) {
      throw StateError('User does not have access to company $companyId');
    }

    final context = <String, dynamic>{
      'lang': _language,
      'tz': _timezone,
      'allowed_company_ids': [companyId],
      ..._customContext,
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    return context;
  }

  /// Create context for multi-company operations
  Map<String, dynamic> getMultiCompanyContext({
    List<int>? companies,
    Map<String, dynamic>? additionalContext,
  }) {
    final activeCompanies = companies ?? getActiveCompanies();

    final context = <String, dynamic>{
      'lang': _language,
      'tz': _timezone,
      'allowed_company_ids': activeCompanies,
      ..._customContext,
    };

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    return context;
  }
}
