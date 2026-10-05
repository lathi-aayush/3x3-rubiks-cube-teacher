import 'move.dart';

class Step {
  final String description;
  final List<Move> moves;
  final String notation;

  const Step({
    required this.description,
    required this.moves,
    required this.notation,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'moves': moves.map((m) => m.name).toList(),
    'notation': notation,
  };

  factory Step.fromJson(Map<String, dynamic> json) => Step(
    description: json['description'] as String,
    moves: (json['moves'] as List<dynamic>)
        .map((e) => Move.values.byName(e as String))
        .toList(),
    notation: json['notation'] as String,
  );
}
