import 'package:bridgecore_flutter_starter/core/services/context_manager.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Multi-company service
class MultiCompanyService {
  static final MultiCompanyService _instance =
      MultiCompanyService._internal();
  factory MultiCompanyService() => _instance;
  MultiCompanyService._internal();

  final OdooRemoteDataSource _remote = OdooRemoteDataSource();
  final CacheDataSource _cache = CacheDataSource();
  final OdooContextManager _contextManager = OdooContextManager();

  Company? _currentCompany;
  List<Company> _availableCompanies = [];

  /// Initialize multi-company support
  Future<void> initialize(List<int> companyIds, int currentCompanyId) async {
    // Load companies
    await loadCompanies(companyIds);

    // Set current company
    await setCurrentCompany(currentCompanyId);
  }

  /// Load available companies
  Future<void> loadCompanies(List<int> companyIds) async {
    try {
      // Try cache first
      final cached = await _cache.get<List<dynamic>>('companies');
      if (cached != null) {
        _availableCompanies = cached
            .map((json) => Company.fromJson(json as Map<String, dynamic>))
            .toList();
        AppLogger.debug('Loaded ${_availableCompanies.length} companies from cache');
        return;
      }

      // Fetch from server
      final companies = await _remote.read(
        model: 'res.company',
        ids: companyIds,
        fields: ['id', 'name', 'currency_id', 'partner_id'],
      );

      _availableCompanies =
          companies.map((json) => Company.fromJson(json)).toList();

      // Cache companies
      await _cache.save(
        key: 'companies',
        data: companies,
        ttl: const Duration(days: 1),
      );

      AppLogger.info('Loaded ${_availableCompanies.length} companies');
    } catch (e) {
      AppLogger.error('Error loading companies: $e');
    }
  }

  /// Set current company
  Future<void> setCurrentCompany(int companyId) async {
    final company = _availableCompanies.firstWhere(
      (c) => c.id == companyId,
      orElse: () => throw Exception('Company $companyId not found'),
    );

    _currentCompany = company;
    await _contextManager.setCompany(companyId);

    AppLogger.info('Current company set to: ${company.name}');
  }

  /// Switch company
  Future<void> switchCompany(int companyId) async {
    await setCurrentCompany(companyId);

    // Clear cache when switching companies
    await _cache.clear();

    AppLogger.info('Switched to company: ${_currentCompany!.name}');
  }

  /// Get current company
  Company? get currentCompany => _currentCompany;

  /// Get available companies
  List<Company> get availableCompanies => List.unmodifiable(_availableCompanies);

  /// Check if multi-company is enabled
  bool get isMultiCompany => _availableCompanies.length > 1;

  /// Get company by ID
  Company? getCompanyById(int id) {
    try {
      return _availableCompanies.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get company-specific data
  Future<List<Map<String, dynamic>>> getCompanyData({
    required String model,
    List<dynamic>? domain,
    List<String>? fields,
    int? limit,
  }) async {
    if (_currentCompany == null) {
      throw Exception('No current company set');
    }

    // Add company filter to domain
    final companyDomain = domain ?? [];
    companyDomain.add(['company_id', '=', _currentCompany!.id]);

    return await _remote.searchRead(
      model: model,
      domain: companyDomain,
      fields: fields,
      limit: limit,
    );
  }

  /// Clear company data
  void clear() {
    _currentCompany = null;
    _availableCompanies.clear();
  }
}

/// Company model
class Company {
  final int id;
  final String name;
  final int? currencyId;
  final int? partnerId;

  Company({
    required this.id,
    required this.name,
    this.currencyId,
    this.partnerId,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      currencyId: json['currency_id'] is List
          ? (json['currency_id'] as List)[0] as int
          : json['currency_id'] as int?,
      partnerId: json['partner_id'] is List
          ? (json['partner_id'] as List)[0] as int
          : json['partner_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency_id': currencyId,
        'partner_id': partnerId,
      };
}
