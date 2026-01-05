import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kurdish_word.dart';
import '../providers/words_provider.dart';
import '../widgets/preview_dialog.dart';

/// Screen for manually entering Kurdish words with dynamic fields
class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});

  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _pronunciationController = TextEditingController();
  
  final List<MapEntry<String, TextEditingController>> _meaningControllers = [];
  final List<MapEntry<String, TextEditingController>> _dialectControllers = [];

  @override
  void dispose() {
    _wordController.dispose();
    _pronunciationController.dispose();
    for (var entry in _meaningControllers) {
      entry.value.dispose();
    }
    for (var entry in _dialectControllers) {
      entry.value.dispose();
    }
    super.dispose();
  }

  void _addMeaningField() {
    setState(() {
      final meaningController = TextEditingController();
      _meaningControllers.add(
        MapEntry('', meaningController),
      );
    });
    // Show dialog to enter language
    _showLanguageDialog(true);
  }

  void _addDialectField() {
    setState(() {
      final dialectController = TextEditingController();
      _dialectControllers.add(
        MapEntry('', dialectController),
      );
    });
    // Show dialog to enter dialect name
    _showLanguageDialog(false);
  }

  void _showLanguageDialog(bool isMeaning) {
    final languageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isMeaning ? 'Enter Language' : 'Enter Dialect Name'),
        content: TextField(
          controller: languageController,
          decoration: InputDecoration(
            labelText: isMeaning ? 'Language (e.g., en, fa, ar)' : 'Dialect (e.g., kurmanji, sorani)',
            hintText: isMeaning ? 'en' : 'kurmanji',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (languageController.text.isNotEmpty) {
                setState(() {
                  if (isMeaning) {
                    final index = _meaningControllers.length - 1;
                    if (index >= 0) {
                      _meaningControllers[index] = MapEntry(
                        languageController.text.trim(),
                        _meaningControllers[index].value,
                      );
                    }
                  } else {
                    final index = _dialectControllers.length - 1;
                    if (index >= 0) {
                      _dialectControllers[index] = MapEntry(
                        languageController.text.trim(),
                        _dialectControllers[index].value,
                      );
                    }
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeMeaningField(int index) {
    setState(() {
      _meaningControllers[index].value.dispose();
      _meaningControllers.removeAt(index);
    });
  }

  void _removeDialectField(int index) {
    setState(() {
      _dialectControllers[index].value.dispose();
      _dialectControllers.removeAt(index);
    });
  }

  void _saveWord() {
    if (_formKey.currentState!.validate()) {
      final meanings = <String, String>{};
      for (var entry in _meaningControllers) {
        if (entry.key.isNotEmpty && entry.value.text.isNotEmpty) {
          meanings[entry.key] = entry.value.text.trim();
        }
      }

      final dialects = <String, String>{};
      for (var entry in _dialectControllers) {
        if (entry.key.isNotEmpty && entry.value.text.isNotEmpty) {
          dialects[entry.key] = entry.value.text.trim();
        }
      }

      final word = KurdishWord(
        word: _wordController.text.trim(),
        meanings: meanings,
        pronunciation: _pronunciationController.text.trim(),
        dialects: dialects,
      );

      ref.read(wordsProvider.notifier).addWord(word);

      // Show preview dialog
      showDialog(
        context: context,
        builder: (context) => PreviewDialog(words: [word]),
      );

      // Clear form
      _wordController.clear();
      _pronunciationController.clear();
      for (var entry in _meaningControllers) {
        entry.value.clear();
      }
      for (var entry in _dialectControllers) {
        entry.value.clear();
      }
      setState(() {
        _meaningControllers.clear();
        _dialectControllers.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word added! Preview shown.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () {
              final words = ref.read(wordsProvider);
              if (words.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No words to preview')),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) => PreviewDialog(words: words),
              );
            },
            tooltip: 'Preview All Words',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _wordController,
              decoration: const InputDecoration(
                labelText: 'Kurdish Word *',
                hintText: 'Enter the Kurdish word',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a word';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pronunciationController,
              decoration: const InputDecoration(
                labelText: 'Pronunciation',
                hintText: 'Enter pronunciation (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meanings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addMeaningField,
                  tooltip: 'Add Meaning',
                ),
              ],
            ),
            ...List.generate(_meaningControllers.length, (index) {
              final entry = _meaningControllers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: entry.key,
                        decoration: InputDecoration(
                          labelText: 'Language',
                          hintText: 'en, fa, ar...',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _meaningControllers[index] = MapEntry(
                              value.trim(),
                              entry.value,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: entry.value,
                        decoration: const InputDecoration(
                          labelText: 'Meaning',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeMeaningField(index),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dialects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addDialectField,
                  tooltip: 'Add Dialect',
                ),
              ],
            ),
            ...List.generate(_dialectControllers.length, (index) {
              final entry = _dialectControllers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: entry.key,
                        decoration: InputDecoration(
                          labelText: 'Dialect Name',
                          hintText: 'kurmanji, sorani...',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _dialectControllers[index] = MapEntry(
                              value.trim(),
                              entry.value,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: entry.value,
                        decoration: const InputDecoration(
                          labelText: 'Dialect Variation',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeDialectField(index),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveWord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Word', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

