import 'package:flutter_test/flutter_test.dart';
import 'package:kurdinal/models/kurdish_word.dart';

void main() {
  group('KurdishWord', () {
    test('should create a KurdishWord with all fields', () {
      final word = KurdishWord(
        word: 'test',
        meanings: {'en': 'test meaning'},
        pronunciation: 'test-pron',
        dialects: {'kurmanji': 'test-dialect'},
      );

      expect(word.word, 'test');
      expect(word.meanings['en'], 'test meaning');
      expect(word.pronunciation, 'test-pron');
      expect(word.dialects['kurmanji'], 'test-dialect');
    });

    test('should convert to JSON', () {
      final word = KurdishWord(
        word: 'test',
        meanings: {'en': 'test meaning'},
        pronunciation: 'test-pron',
        dialects: {'kurmanji': 'test-dialect'},
      );

      final json = word.toJson();
      expect(json['word'], 'test');
      expect(json['meanings']['en'], 'test meaning');
      expect(json['pronunciation'], 'test-pron');
      expect(json['dialects']['kurmanji'], 'test-dialect');
    });

    test('should create from JSON', () {
      final json = {
        'word': 'test',
        'meanings': {'en': 'test meaning'},
        'pronunciation': 'test-pron',
        'dialects': {'kurmanji': 'test-dialect'},
      };

      final word = KurdishWord.fromJson(json);
      expect(word.word, 'test');
      expect(word.meanings['en'], 'test meaning');
      expect(word.pronunciation, 'test-pron');
      expect(word.dialects['kurmanji'], 'test-dialect');
    });

    test('should create a copy with modified fields', () {
      final word = KurdishWord(
        word: 'test',
        meanings: {'en': 'test meaning'},
        pronunciation: 'test-pron',
        dialects: {},
      );

      final modified = word.copyWith(word: 'modified');
      expect(modified.word, 'modified');
      expect(modified.meanings, word.meanings);
      expect(modified.pronunciation, word.pronunciation);
    });
  });
}

