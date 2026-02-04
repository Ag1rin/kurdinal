import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kurdish_word.dart';
import '../services/storage_service.dart';

/// Provider for storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for managing the list of Kurdish words
final wordsProvider = StateNotifierProvider<WordsNotifier, List<KurdishWord>>(
  (ref) => WordsNotifier(ref.read(storageServiceProvider)),
);

class WordsNotifier extends StateNotifier<List<KurdishWord>> {
  final StorageService _storageService;
  bool _isInitialized = false;

  WordsNotifier(this._storageService) : super([]) {
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final words = await _storageService.loadWords();
      state = words;
      _isInitialized = true;
    } catch (e) {
      // If loading fails, start with empty list
      state = [];
      _isInitialized = true;
    }
  }

  Future<void> _saveWords() async {
    if (!_isInitialized) return;
    try {
      await _storageService.saveWords(state);
    } catch (e) {
      // Silently fail - storage is optional
    }
  }

  void addWord(KurdishWord word) {
    state = [...state, word];
    _saveWords();
  }

  void addWords(List<KurdishWord> words) {
    state = [...state, ...words];
    _saveWords();
  }

  void removeWord(int index) {
    state = state.asMap().entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value)
        .toList();
    _saveWords();
  }

  Future<void> clearWords() async {
    state = [];
    await _storageService.clearWords();
  }

  void updateWord(int index, KurdishWord word) {
    final newState = List<KurdishWord>.from(state);
    newState[index] = word;
    state = newState;
    _saveWords();
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

