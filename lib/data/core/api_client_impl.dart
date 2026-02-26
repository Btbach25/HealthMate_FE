import 'package:fe/data/core/api_client.dart';
import 'package:fe/data/services/local_storage_service.dart';

/// Implementation of ApiClient with token management
class ApiClientImpl extends ApiClient {
  // ignore: unused_field
  final LocalStorageService _localStorageService; // Reserved for future token retrieval
  final String _baseUrl;

  ApiClientImpl({
    required String baseUrl,
    required LocalStorageService localStorageService,
  })  : _baseUrl = baseUrl,
        _localStorageService = localStorageService;

  @override
  String get baseUrl => _baseUrl;

  @override
  Future<String?> getAuthToken() async {
    // Get token from local storage or wherever it's stored
    // This is a placeholder - implement based on your auth flow
    // _localStorageService is available for future token retrieval
    // In real implementation, you might store token separately
    // For now, return null or implement token storage
    return null;
  }
}

