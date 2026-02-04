import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/words_provider.dart';
import '../models/kurdish_word.dart';

/// Screen for displaying statistics about words
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  Map<String, int> _getLanguageStats(List<KurdishWord> words) {
    final stats = <String, int>{};
    for (var word in words) {
      for (var lang in word.meanings.keys) {
        stats[lang] = (stats[lang] ?? 0) + 1;
      }
    }
    return stats;
  }

  Map<String, int> _getDialectStats(List<KurdishWord> words) {
    final stats = <String, int>{};
    for (var word in words) {
      for (var dialect in word.dialects.keys) {
        stats[dialect] = (stats[dialect] ?? 0) + 1;
      }
    }
    return stats;
  }

  List<KurdishWord> _findDuplicates(List<KurdishWord> words) {
    final seen = <String, List<KurdishWord>>{};
    final duplicates = <KurdishWord>[];

    for (var word in words) {
      final key = word.word.toLowerCase().trim();
      if (!seen.containsKey(key)) {
        seen[key] = [];
      }
      seen[key]!.add(word);
    }

    for (var entry in seen.entries) {
      if (entry.value.length > 1) {
        duplicates.addAll(entry.value);
      }
    }

    return duplicates;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(wordsProvider);
    final languageStats = _getLanguageStats(words);
    final dialectStats = _getDialectStats(words);
    final duplicates = _findDuplicates(words);
    final wordsWithPronunciation = words.where((w) => w.pronunciation.isNotEmpty).length;
    final wordsWithMeanings = words.where((w) => w.meanings.isNotEmpty).length;
    final wordsWithDialects = words.where((w) => w.dialects.isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: words.isEmpty
          ? const Center(
              child: Text('No words to display statistics'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatItem('Total Words', words.length.toString()),
                        _StatItem(
                          'Words with Pronunciation',
                          '$wordsWithPronunciation (${((wordsWithPronunciation / words.length) * 100).toStringAsFixed(1)}%)',
                        ),
                        _StatItem(
                          'Words with Meanings',
                          '$wordsWithMeanings (${((wordsWithMeanings / words.length) * 100).toStringAsFixed(1)}%)',
                        ),
                        _StatItem(
                          'Words with Dialects',
                          '$wordsWithDialects (${((wordsWithDialects / words.length) * 100).toStringAsFixed(1)}%)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (languageStats.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Languages',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...languageStats.entries.map((entry) => _StatItem(
                                entry.key.toUpperCase(),
                                entry.value.toString(),
                              )),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (dialectStats.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dialects',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...dialectStats.entries.map((entry) => _StatItem(
                                entry.key,
                                entry.value.toString(),
                              )),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (duplicates.isNotEmpty)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                'Duplicate Words',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Found ${duplicates.length} duplicate word(s):',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...duplicates.map((word) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '• ${word.word}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

