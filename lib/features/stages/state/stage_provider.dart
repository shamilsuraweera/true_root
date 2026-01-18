import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stages_api.dart';
import '../models/stage.dart';
import '../../../state/auth_state.dart';

final stagesApiProvider = Provider<StagesApi>((ref) {
  final token = ref.watch(authProvider).accessToken;
  return StagesApi(authToken: token);
});

final stageListProvider = FutureProvider<List<Stage>>((ref) async {
  final api = ref.watch(stagesApiProvider);
  return api.fetchStages();
});
