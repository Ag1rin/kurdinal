import 'dart:convert';
import 'dart:io';
import 'package:arweave/arweave.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for handling Arweave operations including wallet loading and data upload
class ArweaveService {
  static const String _arweaveGateway = 'https://arweave.net';
  static const String _arweaveApiUrl = 'https://arweave.net';
  
  Wallet? _wallet;
  bool get isWalletLoaded => _wallet != null;

  /// Load wallet from JWK file
  Future<void> loadWalletFromFile(File jwkFile) async {
    try {
      final jsonString = await jwkFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _wallet = Wallet.fromJwk(jsonData);
    } catch (e) {
      throw Exception('Failed to load wallet: $e');
    }
  }

  /// Load wallet from JSON string
  Future<void> loadWalletFromJson(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _wallet = Wallet.fromJwk(jsonData);
    } catch (e) {
      throw Exception('Failed to load wallet: $e');
    }
  }

  /// Get wallet address
  String? getWalletAddress() {
    if (_wallet == null) return null;
    try {
      return _wallet!.owner;
    } catch (e) {
      return null;
    }
  }

  /// Upload data to Arweave
  Future<UploadResult> uploadToArweave({
    required String data,
    required Map<String, String> tags,
    void Function(String)? onProgress,
  }) async {
    if (_wallet == null) {
      throw Exception('Wallet not loaded. Please load your wallet first.');
    }

    try {
      // Create Arweave instance
      final arweave = Arweave(
        gatewayUrl: _arweaveGateway,
        apiUrl: _arweaveApiUrl,
      );

      // Create transaction
      final transaction = await arweave.createTransaction(
        data: utf8.encode(data),
        wallet: _wallet!,
      );

      // Add tags
      tags.forEach((key, value) {
        transaction.addTag(key, value);
      });

      // Sign transaction
      await transaction.sign(_wallet!);

      // Post transaction
      onProgress?.call('Signing transaction...');
      final response = await arweave.transactions.post(transaction);

      if (response.statusCode == 200) {
        final txId = transaction.id;
        final viewUrl = '$_arweaveGateway/$txId';
        
        return UploadResult(
          success: true,
          transactionId: txId,
          viewUrl: viewUrl,
        );
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Clear wallet (for security)
  void clearWallet() {
    _wallet = null;
  }
}

/// Result of an Arweave upload operation
class UploadResult {
  final bool success;
  final String? transactionId;
  final String? viewUrl;
  final String? error;

  UploadResult({
    required this.success,
    this.transactionId,
    this.viewUrl,
    this.error,
  });
}

