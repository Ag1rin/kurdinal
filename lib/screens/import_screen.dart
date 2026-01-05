import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/kurdish_word.dart';
import '../providers/words_provider.dart';
import '../widgets/preview_dialog.dart';

/// Screen for importing Kurdish words from JSON file
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  String _status = 'No file selected';
  List<KurdishWord>? _importedWords;

  Future<void> _importJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = await File(filePath).readAsString();
        
        setState(() {
          _status = 'Parsing JSON...';
        });

        try {
          final jsonData = jsonDecode(file);
          List<KurdishWord> words = [];

          if (jsonData is List) {
            // Array of words
            for (var item in jsonData) {
              try {
                words.add(KurdishWord.fromJson(item as Map<String, dynamic>));
              } catch (e) {
                // Skip invalid entries
                continue;
              }
            }
          } else if (jsonData is Map<String, dynamic>) {
            // Single word
            words.add(KurdishWord.fromJson(jsonData));
          }

          setState(() {
            _importedWords = words;
            _status = '${words.length} word(s) imported successfully';
          });

          // Add to provider
          ref.read(wordsProvider.notifier).addWords(words);

          // Show preview
          showDialog(
            context: context,
            builder: (context) => PreviewDialog(words: words),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${words.length} word(s) imported successfully')),
          );
        } catch (e) {
          setState(() {
            _status = 'Error parsing JSON: $e';
            _importedWords = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing JSON: $e')),
          );
        }
      } else {
        setState(() {
          _status = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _importedWords = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import JSON'),
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
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.upload_file,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Import Kurdish Words from JSON',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _importJsonFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select JSON File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JSON Format:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Single word:\n'
                    '{\n'
                    '  "word": "example",\n'
                    '  "meanings": {"en": "meaning", "fa": "معنی"},\n'
                    '  "pronunciation": "pron",\n'
                    '  "dialects": {"kurmanji": "var1", "sorani": "var2"}\n'
                    '}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Or array of words: [{...}, {...}]',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
