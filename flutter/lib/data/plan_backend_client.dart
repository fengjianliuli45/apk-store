import 'dart:convert';
import 'dart:io';

/// Small OpenAPI-aligned client for POST /api/v1/plans.
///
/// The planner remains offline-first. Production builds enable cloud sync
/// with --dart-define=STOPWATCH_API_BASE_URL=... and
/// --dart-define=STOPWATCH_API_TOKEN=.... Without both values, plans stay in
/// the local immutable history and can be synced later.
abstract interface class PlanRemoteStore {
  bool get isConfigured;

  Future<void> savePlan({
    required String plannerVersion,
    required Map<String, dynamic> inputSnapshot,
    required Map<String, dynamic> planJson,
    required String changeReason,
  });
}

class PlanBackendClient implements PlanRemoteStore {
  const PlanBackendClient({
    this.baseUrl = const String.fromEnvironment('STOPWATCH_API_BASE_URL'),
    this.accessToken = const String.fromEnvironment('STOPWATCH_API_TOKEN'),
  });

  final String baseUrl;
  final String accessToken;

  @override
  bool get isConfigured => baseUrl.trim().isNotEmpty && accessToken.trim().isNotEmpty;

  @override
  Future<void> savePlan({
    required String plannerVersion,
    required Map<String, dynamic> inputSnapshot,
    required Map<String, dynamic> planJson,
    required String changeReason,
  }) async {
    if (!isConfigured) throw StateError('Plan backend is not configured');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final root = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      final endpoint = Uri.parse('$root/api/v1/plans');
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.write(jsonEncode({
        'plannerVersion': plannerVersion,
        'generatedBy': 'dart',
        'inputSnapshot': inputSnapshot,
        'planJson': planJson,
        'changeReason': changeReason,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Plan sync failed (${response.statusCode}): $body',
          uri: endpoint,
        );
      }
    } finally {
      client.close(force: true);
    }
  }
}
