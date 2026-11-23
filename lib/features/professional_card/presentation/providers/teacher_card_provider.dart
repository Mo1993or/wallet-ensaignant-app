import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wallet_enseignant/features/professional_card/data/datasources/teacher_card_remote_datasource.dart';

import '../../../../app/app_providers.dart';
import '../../data/models/teacher_card_model.dart';

final teacherCardProvider =
    AsyncNotifierProvider<TeacherCardNotifier, TeacherCardModel>(
      TeacherCardNotifier.new,
    );

class TeacherCardNotifier extends AsyncNotifier<TeacherCardModel> {
  @override
  Future<TeacherCardModel> build() async {
    return _dataSource.getMyCard();
  }

  TeacherCardRemoteDataSource get _dataSource =>
      ref.read(teacherCardRemoteDataSourceProvider);

  /// Recharge les informations de la carte professionnelle.
  Future<void> reload() async {
    final previousState = state;

    state = const AsyncLoading<TeacherCardModel>().copyWithPrevious(
      previousState,
    );

    state = await AsyncValue.guard(() => _dataSource.getMyCard());
  }

  // La vérification QR est mise de côté pour le moment.
}
