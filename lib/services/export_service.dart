import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/kurdish_word.dart';

/// Service for exporting words to JSON file
class ExportService {
  /// Export words to JSON file
  Future<File> exportToJson(List<KurdishWord> words, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      
      String jsonString;
      if (words.length == 1) {
        jsonString = const JsonEncoder.withIndent('  ').convert(words.first.toJson());
      } else {
        jsonString = const JsonEncoder.withIndent('  ').convert(
          words.map((w) => w.toJson()).toList(),
        );
      }
      
      await file.writeAsString(jsonString);
      return file;
    } catch (e) {
      throw Exception('Failed to export words: $e');
    }
  }

  /// Get export file path
  Future<String> getExportPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}

