import '../cube/facelets.dart';
import 'stage.dart';

class Session {
  final Facelets facelets;
  final Stage currentStage;
  final int currentStepIndex;
  final DateTime lastUpdated;

  const Session({
    required this.facelets,
    required this.currentStage,
    required this.currentStepIndex,
    required this.lastUpdated,
  });

  Session copyWith({
    Facelets? facelets,
    Stage? currentStage,
    int? currentStepIndex,
    DateTime? lastUpdated,
  }) {
    return Session(
      facelets: facelets ?? List<int>.from(this.facelets),
      currentStage: currentStage ?? this.currentStage,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'facelets': facelets,
    'currentStage': currentStage.name,
    'currentStepIndex': currentStepIndex,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    facelets: List<int>.from(json['facelets'] as List),
    currentStage: Stage.values.byName(json['currentStage'] as String),
    currentStepIndex: json['currentStepIndex'] as int,
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  );
}
