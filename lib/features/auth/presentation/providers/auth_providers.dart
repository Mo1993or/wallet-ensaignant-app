import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet_enseignant/features/auth/data/datasources/teacher_verification_remote.datasource.dart';
import 'package:wallet_enseignant/features/auth/domain/usecases/verify_teacher_usecase.dart';

import '../../../../app/app_providers.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/device_auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../domain/repositories/auth_repository.dart';

import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_professional_card_usecase.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);

  return AuthRemoteDataSource(dio: dio);
});

final deviceAuthRemoteDataSourceProvider = Provider<DeviceAuthRemoteDataSource>(
  (ref) {
    final dio = ref.watch(dioProvider);

    return DeviceAuthRemoteDataSource(dio: dio);
  },
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);

  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
});

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return SendOtpUseCase(repository);
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return VerifyOtpUseCase(repository);
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return RegisterUseCase(repository);
});

/// Nouveau UseCase : vérification de la carte professionnelle APPS.
final verifyProfessionalCardUseCaseProvider =
    Provider<VerifyProfessionalCardUseCase>((ref) {
      final repository = ref.watch(authRepositoryProvider);

      return VerifyProfessionalCardUseCase(repository);
    });

/// Ancien système de vérification professionnelle.
/// Conservé provisoirement pour éviter de casser les écrans qui l'utilisent.
final teacherVerificationRemoteDataSourceProvider =
    Provider<TeacherVerificationRemoteDataSource>((ref) {
      final dio = ref.watch(dioProvider);

      return TeacherVerificationRemoteDataSource(dio: dio);
    });

final verifyTeacherUseCaseProvider = Provider<VerifyTeacherUseCase>((ref) {
  final dataSource = ref.watch(teacherVerificationRemoteDataSourceProvider);

  return VerifyTeacherUseCase(dataSource);
});
