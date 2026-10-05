import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/data/session_repository.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/models/session.dart';
import 'package:rubiks_cube_teacher/domain/models/stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SessionRepository Tests', () {
    late SessionRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves, loads, and clears session', () async {
      final prefs = await SharedPreferences.getInstance();
      repository = SessionRepository(prefs);

      expect(repository.hasActiveSession(), isFalse);
      expect(repository.loadCurrentSession(), isNull);

      final session = Session(
        facelets: FaceletConstants.solved,
        currentStage: Stage.whiteCorners,
        currentStepIndex: 2,
        lastUpdated: DateTime.now(),
      );

      await repository.saveCurrentSession(session);
      expect(repository.hasActiveSession(), isTrue);

      final loaded = repository.loadCurrentSession();
      expect(loaded, isNotNull);
      expect(loaded!.currentStage, Stage.whiteCorners);
      expect(loaded.currentStepIndex, 2);
      expect(loaded.facelets, FaceletConstants.solved);

      await repository.clearCurrentSession();
      expect(repository.hasActiveSession(), isFalse);
      expect(repository.loadCurrentSession(), isNull);
    });
  });
}
