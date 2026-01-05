// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kurdish_word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KurdishWord _$KurdishWordFromJson(Map<String, dynamic> json) => KurdishWord(
  word: json['word'] as String,
  meanings: Map<String, String>.from(json['meanings'] as Map),
  pronunciation: json['pronunciation'] as String,
  dialects: Map<String, String>.from(json['dialects'] as Map),
);

Map<String, dynamic> _$KurdishWordToJson(KurdishWord instance) =>
    <String, dynamic>{
      'word': instance.word,
      'meanings': instance.meanings,
      'pronunciation': instance.pronunciation,
      'dialects': instance.dialects,
    };
