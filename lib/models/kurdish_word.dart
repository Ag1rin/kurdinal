import 'package:json_annotation/json_annotation.dart';

part 'kurdish_word.g.dart';

/// Model representing a Kurdish word with its meanings, pronunciation, and dialects
@JsonSerializable()
class KurdishWord {
  final String word;
  final Map<String, String> meanings;
  final String pronunciation;
  final Map<String, String> dialects;

  KurdishWord({
    required this.word,
    required this.meanings,
    required this.pronunciation,
    required this.dialects,
  });

  factory KurdishWord.fromJson(Map<String, dynamic> json) =>
      _$KurdishWordFromJson(json);

  Map<String, dynamic> toJson() => _$KurdishWordToJson(this);

  KurdishWord copyWith({
    String? word,
    Map<String, String>? meanings,
    String? pronunciation,
    Map<String, String>? dialects,
  }) {
    return KurdishWord(
      word: word ?? this.word,
      meanings: meanings ?? this.meanings,
      pronunciation: pronunciation ?? this.pronunciation,
      dialects: dialects ?? this.dialects,
    );
  }
}

