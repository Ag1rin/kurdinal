import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/kurdish_word.dart';
import '../providers/words_provider.dart';
import '../services/export_service.dart';
import '../widgets/preview_dialog.dart';
import 'upload_screen.dart';
import 'form_screen.dart';

/// Screen for displaying and managing list of words
class WordsListScreen extends ConsumerStatefulWidget {
  const WordsListScreen({super.key});

  @override
  ConsumerState<WordsListScreen> createState() => _WordsListScreenState();
}

class _WordsListScreenState extends ConsumerState<WordsListScreen> {
  final ExportService _exportService = ExportService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KurdishWord> _filterWords(List<KurdishWord> words) {
    if (_searchQuery.isEmpty) return words;
    
    final query = _searchQuery.toLowerCase();
    return words.where((word) {
      if (word.word.toLowerCase().contains(query)) return true;
      if (word.pronunciation.toLowerCase().contains(query)) return true;
      if (word.meanings.values.any((m) => m.toLowerCase().contains(query))) return true;
      if (word.dialects.values.any((d) => d.toLowerCase().contains(query))) return true;
      return false;
    }).toList();
  }

  Future<void> _exportWords() async {
    final words = ref.read(wordsProvider);
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No words to export')),
      );
      return;
    }

    try {
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'kurdish_words_$timestamp.json';
      
      final file = await _exportService.exportToJson(words, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Words exported to: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportToFile() async {
    final words = ref.read(wordsProvider);
    if (words.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No words to export')),
      );
      return;
    }

    try {
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'kurdish_words_$timestamp.json';
      
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save JSON File',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        String jsonString;
        if (words.length == 1) {
          jsonString = const JsonEncoder.withIndent('  ').convert(words.first.toJson());
        } else {
          jsonString = const JsonEncoder.withIndent('  ').convert(
            words.map((w) => w.toJson()).toList(),
          );
        }
        
        await file.writeAsString(jsonString);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Words exported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _editWord(int index, KurdishWord word) {
    // Navigate to form screen with word data for editing
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormScreen(editWord: word, editIndex: index),
      ),
    );
  }

  void _deleteWord(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: const Text('Are you sure you want to delete this word?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).removeWord(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Word deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(wordsProvider);
    final filteredWords = _filterWords(words);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Words List'),
        actions: [
          if (words.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadScreen(words: words),
                  ),
                );
              },
              tooltip: 'Upload to Arweave',
            ),
          if (words.isNotEmpty)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Export to File'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'export') {
                  _exportToFile();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search words...',
                hintText: 'Search by word, meaning, or dialect',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (words.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No words yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FormScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Word'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredWords.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final word = filteredWords[index];
                  final originalIndex = words.indexOf(word);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        word.word,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (word.pronunciation.isNotEmpty)
                            Text('Pronunciation: ${word.pronunciation}'),
                          if (word.meanings.isNotEmpty)
                            Text(
                              'Meanings: ${word.meanings.values.take(2).join(", ")}${word.meanings.length > 2 ? "..." : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editWord(originalIndex, word),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWord(originalIndex),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => PreviewDialog(words: [word]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          if (words.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total: ${words.length} word(s)${_searchQuery.isNotEmpty ? " (${filteredWords.length} filtered)" : ""}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Word',
      ),
    );
  }
}

