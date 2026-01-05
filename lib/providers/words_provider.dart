import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kurdish_word.dart';

/// Provider for managing the list of Kurdish words
final wordsProvider = StateNotifierProvider<WordsNotifier, List<KurdishWord>>(
  (ref) => WordsNotifier(),
);

class WordsNotifier extends StateNotifier<List<KurdishWord>> {
  WordsNotifier() : super([]);

  void addWord(KurdishWord word) {
    state = [...state, word];
  }

  void addWords(List<KurdishWord> words) {
    state = [...state, ...words];
  }

  void removeWord(int index) {
    state = state.where((_, i) => i != index).toList();
  }

  void clearWords() {
    state = [];
  }

  void updateWord(int index, KurdishWord word) {
    final newState = List<KurdishWord>.from(state);
    newState[index] = word;
    state = newState;
  }
}

/// Provider for the current word being edited
final currentWordProvider = StateProvider<KurdishWord?>((ref) => null);

/// Provider for upload status
final uploadStatusProvider = StateProvider<UploadStatus>((ref) => UploadStatus.idle);

enum UploadStatus {
  idle,
  uploading,
  success,
  error,
}

