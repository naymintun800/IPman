import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'domain_registry_service.g.dart';

class DomainRegistryFailure implements Exception {
  final Object error;
  final StackTrace? stackTrace;

  const DomainRegistryFailure(this.error, [this.stackTrace]);
}

@riverpod
class DomainRegistryService extends _$DomainRegistryService with InfraLogger {
  // NocoDB v2 API config
  String get _nocoCdbApiUrl => dotenv.env['NOCO_API_URL'] ?? '';
  static const String _tableName = 'mmhobduon4w616j';

  // Get API key from .env file
  String get _apiKey => dotenv.env['NOCO_API_KEY'] ?? '';

  @override
  Future<Map<String, String>> build() async {
    try {
      return await _fetchDomains();
    } catch (e, stackTrace) {
      loggy.error('Failed to fetch domains', e, stackTrace);
      // Return empty map on initial failure, but don't crash the app
      return {
        'basic': '',
        'gold': '',
      };
    }
  }

  Future<Map<String, String>> _fetchDomains() async {
    final dio = Dio();

    // For API v2, use 'xc-token' instead of 'xc-auth'
    dio.options.headers['xc-token'] = _apiKey;

    // Correct API v2 endpoint format
    final response = await dio.get('$_nocoCdbApiUrl/api/v2/tables/$_tableName/records');

    if (response.statusCode != 200) {
      throw DomainRegistryFailure('Failed to fetch domains: ${response.statusCode}');
    }

    // API v2 response structure is different
    final responseData = response.data as Map<String, dynamic>;

    // Type-safe check for list existence and emptiness
    final list = responseData['list'];
    if (list == null) {
      throw DomainRegistryFailure('No list found in response');
    }

    if (list is! List || list.isEmpty) {
      throw DomainRegistryFailure('No domain records found');
    }

    final record = list[0] as Map<String, dynamic>?;
    if (record == null) {
      throw DomainRegistryFailure('Empty domain record');
    }

    // Extract domains from the first record
    return {
      'basic': record['basic']?.toString() ?? '',
      'gold': record['gold']?.toString() ?? '',
    };
  }

  // Force refresh domains from NocoDB
  Future<void> refreshDomains() async {
    state = const AsyncLoading();
    try {
      final domains = await _fetchDomains();
      state = AsyncData(domains);
      loggy.info('Domains refreshed: $domains');
    } catch (e, stackTrace) {
      loggy.error('Failed to refresh domains', e, stackTrace);
      state = AsyncError(DomainRegistryFailure(e, stackTrace), stackTrace);
    }
  }
}
