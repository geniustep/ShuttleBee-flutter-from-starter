import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:bridgecore_flutter_starter/core/data/datasources/remote_data_source.dart';
import 'package:bridgecore_flutter_starter/core/data/datasources/local_data_source.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Advanced search service
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final OdooRemoteDataSource _remote = OdooRemoteDataSource();
  final CacheDataSource _cache = CacheDataSource();
  final List<String> _recentSearches = [];

  /// Search across multiple models
  Future<Map<String, List<Map<String, dynamic>>>> globalSearch({
    required String query,
    List<String>? models,
    int limit = 10,
    bool useCache = true,
  }) async {
    if (query.trim().isEmpty) {
      return {};
    }

    // Add to recent searches
    await _addToRecentSearches(query);

    // Try cache first
    if (useCache) {
      final cached = await _cache.get<Map<String, dynamic>>(
        'search:$query',
      );
      if (cached != null) {
        AppLogger.debug('Returning cached search results');
        return cached.map(
          (key, value) => MapEntry(
            key,
            (value as List).cast<Map<String, dynamic>>(),
          ),
        );
      }
    }

    final results = <String, List<Map<String, dynamic>>>{};

    // Default models to search
    final searchModels = models ??
        [
          'res.partner',
          'product.product',
          'sale.order',
          'account.move',
        ];

    // Search in each model
    for (final model in searchModels) {
      try {
        final domain = _buildSearchDomain(model, query);
        final modelResults = await _remote.searchRead(
          model: model,
          domain: domain,
          limit: limit,
        );

        if (modelResults.isNotEmpty) {
          results[model] = modelResults;
        }
      } catch (e) {
        AppLogger.error('Error searching in $model: $e');
      }
    }

    // Cache results
    await _cache.save(
      key: 'search:$query',
      data: results,
      ttl: const Duration(minutes: 5),
    );

    return results;
  }

  /// Build search domain based on model
  List<dynamic> _buildSearchDomain(String model, String query) {
    switch (model) {
      case 'res.partner':
        return [
          '|',
          ['name', 'ilike', query],
          '|',
          ['email', 'ilike', query],
          ['phone', 'ilike', query],
        ];

      case 'product.product':
        return [
          '|',
          ['name', 'ilike', query],
          '|',
          ['default_code', 'ilike', query],
          ['barcode', 'ilike', query],
        ];

      case 'sale.order':
        return [
          '|',
          ['name', 'ilike', query],
          ['partner_id.name', 'ilike', query],
        ];

      case 'account.move':
        return [
          '|',
          ['name', 'ilike', query],
          ['partner_id.name', 'ilike', query],
        ];

      default:
        return [['name', 'ilike', query]];
    }
  }

  /// Search in specific model with filters
  Future<List<Map<String, dynamic>>> advancedSearch({
    required String model,
    String? query,
    List<SearchFilter>? filters,
    String? sortBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    final domain = <dynamic>[];

    // Add query domain
    if (query != null && query.isNotEmpty) {
      domain.addAll(_buildSearchDomain(model, query));
    }

    // Add filters
    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        if (domain.isNotEmpty) {
          domain.insert(0, filter.operator.symbol);
        }
        domain.add(filter.toDomain());
      }
    }

    // Build order string
    final order = sortBy != null
        ? '$sortBy ${ascending ? 'ASC' : 'DESC'}'
        : null;

    return await _remote.searchRead(
      model: model,
      domain: domain,
      limit: limit,
      offset: offset,
      order: order,
    );
  }

  /// Add to recent searches
  Future<void> _addToRecentSearches(String query) async {
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 20) {
        _recentSearches.removeLast();
      }

      await _cache.save(
        key: 'recent_searches',
        data: _recentSearches,
        ttl: const Duration(days: 30),
      );
    }
  }

  /// Get recent searches
  Future<List<String>> getRecentSearches() async {
    if (_recentSearches.isEmpty) {
      final cached = await _cache.get<List<dynamic>>('recent_searches');
      if (cached != null) {
        _recentSearches.addAll(cached.cast<String>());
      }
    }
    return List.unmodifiable(_recentSearches);
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    await _cache.delete('recent_searches');
  }
}

/// Voice search service
class VoiceSearchService {
  static final VoiceSearchService _instance = VoiceSearchService._internal();
  factory VoiceSearchService() => _instance;
  VoiceSearchService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    try {
      return await _speech.initialize();
    } catch (e) {
      AppLogger.error('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening
  Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
    String? localeId,
  }) async {
    if (_isListening) {
      AppLogger.warning('Already listening');
      return;
    }

    final available = await isAvailable();
    if (!available) {
      onError?.call('Speech recognition not available');
      return;
    }

    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          stopListening();
        }
      },
      localeId: localeId,
    );

    AppLogger.info('Started listening for voice input');
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      AppLogger.info('Stopped listening');
    }
  }

  /// Cancel listening
  Future<void> cancel() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      AppLogger.info('Cancelled listening');
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    return await _speech.locales();
  }
}

/// Search filter
class SearchFilter {
  final String field;
  final FilterOperator operator;
  final dynamic value;
  final LogicalOperator logicalOperator;

  SearchFilter({
    required this.field,
    required this.operator,
    required this.value,
    this.logicalOperator = LogicalOperator.and,
  });

  List<dynamic> toDomain() {
    return [field, operator.symbol, value];
  }
}

/// Filter operator
enum FilterOperator {
  equals('='),
  notEquals('!='),
  like('like'),
  ilike('ilike'),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  lessThan('<'),
  lessThanOrEqual('<='),
  inList('in'),
  notInList('not in');

  final String symbol;
  const FilterOperator(this.symbol);
}

/// Logical operator
enum LogicalOperator {
  and('&'),
  or('|'),
  not('!');

  final String symbol;
  const LogicalOperator(this.symbol);
}
