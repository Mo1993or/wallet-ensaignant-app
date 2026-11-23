import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../data/services/device_auth_service.dart';
import 'auth_providers.dart';

final deviceAuthServiceProvider = Provider<DeviceAuthService>((ref) {
  final remoteDataSource = ref.watch(deviceAuthRemoteDataSourceProvider);

  final secureStorage = ref.watch(secureStorageProvider);

  return DeviceAuthService(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
  );
});
