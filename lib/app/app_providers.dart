import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:wallet_enseignant/core/network/dio_client.dart';
import 'package:wallet_enseignant/core/security/secure_storage_service.dart';
import 'package:wallet_enseignant/core/security/installation_state_service.dart';
import 'package:wallet_enseignant/features/professional_card/data/datasources/teacher_card_remote_datasource.dart';

import 'app_router.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final installationStateServiceProvider = Provider<InstallationStateService>((
  ref,
) {
  final secureStorage = ref.watch(secureStorageProvider);

  return InstallationStateService(secureStorage: secureStorage);
});

final startupDestinationProvider = FutureProvider<AppStartupDestination>((
  ref,
) async {
  final installationService = ref.watch(installationStateServiceProvider);

  return installationService.resolveDestination();
});

final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);

  return DioClient.create(secureStorage: secureStorage);
});

final teacherCardRemoteDataSourceProvider =
    Provider<TeacherCardRemoteDataSource>((ref) {
      final dio = ref.watch(dioProvider);

      return TeacherCardRemoteDataSource(dio: dio);
    });

final appRouterProvider = Provider<GoRouter>((ref) {
  return createAppRouter();
});
