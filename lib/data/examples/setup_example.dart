// Example: How to setup API services
// This file shows how to configure the app to use either Mock or API services

import 'package:fe/data/core/api_client_impl.dart';
import 'package:fe/data/repositories/auth_repository.dart';
import 'package:fe/data/repositories/family_repository.dart';
import 'package:fe/data/repositories/home_repository.dart';
import 'package:fe/data/repositories/stats_repository.dart';
import 'package:fe/data/services/api_family_service.dart';
import 'package:fe/data/services/auth_service.dart';
import 'package:fe/data/services/family_service.dart';
import 'package:fe/data/services/home_service.dart';
import 'package:fe/data/services/local_storage_service.dart';
import 'package:fe/data/services/mock_auth_service.dart';
import 'package:fe/data/services/mock_family_service.dart';
import 'package:fe/data/services/mock_home_service.dart';
import 'package:fe/data/services/mock_stats_service.dart';
import 'package:fe/data/services/stats_service.dart';

/// Example: Setup with Mock Services (Current setup)
void setupWithMockServices() {
  // Services
  final authService = MockAuthService();
  final localStorageService = LocalStorageService();
  final homeService = MockHomeService();
  final statsService = MockStatsService();
  final familyService = MockFamilyService();

  // Repositories
  final authRepository = AuthRepository(
    authService: authService,
    localStorageService: localStorageService,
  );
  final homeRepository = HomeRepository(homeService: homeService);
  final statsRepository = StatsRepository(statsService: statsService);
  final familyRepository = FamilyRepository(familyService: familyService);

  // Use these repositories in your app
}

/// Example: Setup with API Services (For production)
void setupWithApiServices() {
  // Configuration
  const apiBaseUrl = 'https://api.yourdomain.com';
  
  // Core services
  final localStorageService = LocalStorageService();
  
  // API Client
  final apiClient = ApiClientImpl(
    baseUrl: apiBaseUrl,
    localStorageService: localStorageService,
  );

  // API Services
  final familyService = ApiFamilyService(apiClient: apiClient);
  // TODO: Implement other API services
  // final authService = ApiAuthService(apiClient: apiClient);
  // final homeService = ApiHomeService(apiClient: apiClient);
  // final statsService = ApiStatsService(apiClient: apiClient);

  // For now, use mock for services that don't have API implementation yet
  final authService = MockAuthService();
  final homeService = MockHomeService();
  final statsService = MockStatsService();

  // Repositories (same interface, different implementations)
  final authRepository = AuthRepository(
    authService: authService,
    localStorageService: localStorageService,
  );
  final homeRepository = HomeRepository(homeService: homeService);
  final statsRepository = StatsRepository(statsService: statsService);
  final familyRepository = FamilyRepository(familyService: familyService);

  // Use these repositories in your app
}

/// Example: Setup with conditional logic (Mock for dev, API for prod)
void setupWithConditionalServices({required bool useMock}) {
  final localStorageService = LocalStorageService();
  
  // Family Service
  final FamilyService familyService;
  if (useMock) {
    familyService = MockFamilyService();
  } else {
    final apiClient = ApiClientImpl(
      baseUrl: 'https://api.yourdomain.com',
      localStorageService: localStorageService,
    );
    familyService = ApiFamilyService(apiClient: apiClient);
  }

  // Other services...
  final authService = MockAuthService();
  final homeService = MockHomeService();
  final statsService = MockStatsService();

  // Repositories
  final authRepository = AuthRepository(
    authService: authService,
    localStorageService: localStorageService,
  );
  final homeRepository = HomeRepository(homeService: homeService);
  final statsRepository = StatsRepository(statsService: statsService);
  final familyRepository = FamilyRepository(familyService: familyService);

  // Use these repositories in your app
}

