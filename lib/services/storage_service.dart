import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kurdish_word.dart';

/// Service for local storage of words
class StorageService {
  static const String _wordsKey = 'kurdish_words';
  static const String _transactionsKey = 'arweave_transactions';

  /// Save words to local storage
  Future<void> saveWords(List<KurdishWord> words) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wordsJson = words.map((w) => w.toJson()).toList();
      await prefs.setString(_wordsKey, jsonEncode(wordsJson));
    } catch (e) {
      throw Exception('Failed to save words: $e');
    }
  }

  /// Load words from local storage
  Future<List<KurdishWord>> loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wordsJsonString = prefs.getString(_wordsKey);
      
      if (wordsJsonString == null) {
        return [];
      }

      final wordsJson = jsonDecode(wordsJsonString) as List;
      return wordsJson
          .map((json) => KurdishWord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load words: $e');
    }
  }

  /// Clear all words from storage
  Future<void> clearWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_wordsKey);
    } catch (e) {
      throw Exception('Failed to clear words: $e');
    }
  }

  /// Save transaction history
  Future<void> saveTransaction({
    required String transactionId,
    required String viewUrl,
    required int wordCount,
    required DateTime timestamp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJsonString = prefs.getString(_transactionsKey);
      
      List<Map<String, dynamic>> transactions = [];
      if (transactionsJsonString != null) {
        transactions = List<Map<String, dynamic>>.from(
          jsonDecode(transactionsJsonString),
        );
      }

      transactions.add({
        'transactionId': transactionId,
        'viewUrl': viewUrl,
        'wordCount': wordCount,
        'timestamp': timestamp.toIso8601String(),
      });

      await prefs.setString(_transactionsKey, jsonEncode(transactions));
    } catch (e) {
      throw Exception('Failed to save transaction: $e');
    }
  }

  /// Load transaction history
  Future<List<Map<String, dynamic>>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJsonString = prefs.getString(_transactionsKey);
      
      if (transactionsJsonString == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(
        jsonDecode(transactionsJsonString),
      );
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }
}

