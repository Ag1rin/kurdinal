import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as crypto;

/// Service for handling Arweave operations including wallet loading and data upload
/// Uses Arweave REST API directly for maximum compatibility
class ArweaveService {
  static const String _arweaveGateway = 'https://arweave.net';
  static const String _arweaveApiUrl = 'https://arweave.net';
  
  Map<String, dynamic>? _wallet;
  bool get isWalletLoaded => _wallet != null;

  /// Load wallet from JWK file
  Future<void> loadWalletFromFile(File jwkFile) async {
    try {
      final jsonString = await jwkFile.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _wallet = jsonData;
    } catch (e) {
      throw Exception('Failed to load wallet: $e');
    }
  }

  /// Load wallet from JSON string
  Future<void> loadWalletFromJson(String jsonString) async {
    try {
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _wallet = jsonData;
    } catch (e) {
      throw Exception('Failed to load wallet: $e');
    }
  }

  /// Get wallet address (owner public key)
  String? getWalletAddress() {
    if (_wallet == null) return null;
    try {
      // In Arweave JWK, 'n' is the modulus which is used to derive the address
      // For simplicity, we'll use a hash of the public key
      final n = _wallet!['n'] as String?;
      if (n != null) {
        final bytes = base64Url.decode(n);
        final hash = sha256.convert(bytes);
        return base64Url.encode(hash.bytes);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload data to Arweave using REST API
  Future<UploadResult> uploadToArweave({
    required String data,
    required Map<String, String> tags,
    void Function(String)? onProgress,
  }) async {
    if (_wallet == null) {
      throw Exception('Wallet not loaded. Please load your wallet first.');
    }

    try {
      onProgress?.call('Creating transaction...');
      
      // Encode data
      final dataBytes = utf8.encode(data);
      
      // Create transaction
      final transaction = await _createTransaction(
        data: dataBytes,
        tags: tags,
      );

      onProgress?.call('Signing transaction...');
      
      // Sign transaction
      await _signTransaction(transaction);

      onProgress?.call('Posting to Arweave...');
      
      // Post transaction
      final response = await http.post(
        Uri.parse('$_arweaveApiUrl/tx'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transaction),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final txId = responseData['id'] as String? ?? transaction['id'] as String;
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

  /// Create an Arweave transaction
  Future<Map<String, dynamic>> _createTransaction({
    required List<int> data,
    required Map<String, String> tags,
  }) async {
    // Get last transaction ID (anchor)
    final anchorResponse = await http.get(Uri.parse('$_arweaveApiUrl/tx_anchor'));
    final anchor = anchorResponse.body.trim();

    // Get reward
    final rewardResponse = await http.get(
      Uri.parse('$_arweaveApiUrl/price/${data.length}'),
    );
    final reward = rewardResponse.body.trim();

    // Create transaction
    final transaction = {
      'format': 2,
      'id': '', // Will be set after signing
      'last_tx': anchor,
      'owner': _wallet!['n'],
      'tags': tags.entries.map((e) => {
        'name': base64.encode(utf8.encode(e.key)),
        'value': base64.encode(utf8.encode(e.value)),
      }).toList(),
      'target': '',
      'quantity': '0',
      'data': base64.encode(data),
      'reward': reward,
    };

    return transaction;
  }

  /// Sign an Arweave transaction
  Future<void> _signTransaction(Map<String, dynamic> transaction) async {
    try {
      // Get the private key components from wallet
      final n = _wallet!['n'] as String;
      final e = _wallet!['e'] as String;
      final d = _wallet!['d'] as String;
      final p = _wallet!['p'] as String;
      final q = _wallet!['q'] as String;
      final dp = _wallet!['dp'] as String;
      final dq = _wallet!['dq'] as String;
      final qi = _wallet!['qi'] as String;

      // Create deep copy for signing (remove id and signature)
      final txCopy = Map<String, dynamic>.from(transaction);
      txCopy.remove('id');
      txCopy.remove('signature');

      // Serialize transaction
      final txString = _serializeTransaction(txCopy);
      final txBytes = utf8.encode(txString);

      // Sign with RSA
      final signature = await _rsaSign(txBytes, n, e, d, p, q, dp, dq, qi);
      
      // Calculate transaction ID (hash of signature)
      final txId = base64Url.encode(sha256.convert(signature).bytes);

      transaction['id'] = txId;
      transaction['signature'] = base64.encode(signature);
    } catch (e) {
      throw Exception('Failed to sign transaction: $e');
    }
  }

  /// Serialize transaction for signing
  String _serializeTransaction(Map<String, dynamic> tx) {
    final owner = tx['owner'] as String;
    final target = tx['target'] as String;
    final quantity = tx['quantity'] as String;
    final lastTx = tx['last_tx'] as String;
    final reward = tx['reward'] as String;
    final tags = tx['tags'] as List;
    final data = tx['data'] as String;

    final tagString = tags.map((tag) {
      final name = tag['name'] as String;
      final value = tag['value'] as String;
      return '$name$value';
    }).join();

    return '$owner$target$quantity$lastTx$reward$tagString$data';
  }

  /// Sign data with RSA private key using RSA-PSS
  /// Note: This is a simplified implementation. For production use, consider using
  /// the arweave-dart package from GitHub (CDDelta/arweave-dart) or implement
  /// proper RSA-PSS signing according to Arweave's specifications.
  /// 
  /// IMPORTANT: The current implementation is a placeholder. Full RSA-PSS signing
  /// requires proper implementation of Arweave's specific signing format.
  /// For now, this will throw an error indicating that a proper SDK should be used.
  Future<Uint8List> _rsaSign(
    List<int> data,
    String n,
    String e,
    String d,
    String p,
    String q,
    String dp,
    String dq,
    String qi,
  ) async {
    // TODO: Implement proper RSA-PSS signing for Arweave
    // This requires:
    // 1. Proper RSA key construction from JWK
    // 2. RSA-PSS padding according to Arweave specs
    // 3. Correct signature format
    
    // For now, throw an informative error
    throw Exception(
      'RSA signing not fully implemented.\n'
      'Please use a proper Arweave SDK for production:\n'
      '- arweave-dart from GitHub (CDDelta/arweave-dart)\n'
      '- Or implement proper RSA-PSS signing according to Arweave documentation\n\n'
      'The wallet structure is correct, but signing requires additional implementation.'
    );
  }

  /// Decode base64url string
  Uint8List _base64UrlDecode(String input) {
    // Convert base64url to base64
    String base64 = input.replaceAll('-', '+').replaceAll('_', '/');
    // Add padding if needed
    switch (base64.length % 4) {
      case 1:
        base64 += '===';
        break;
      case 2:
        base64 += '==';
        break;
      case 3:
        base64 += '=';
        break;
    }
    return base64Decode(base64);
  }

  /// Convert bytes to BigInt (using Dart's built-in BigInt)
  BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = result * BigInt.from(256) + BigInt.from(bytes[i]);
    }
    return result;
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

