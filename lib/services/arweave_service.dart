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
    try {
      // Hash the data with SHA-256
      final hash = sha256.convert(data);
      final hashBytes = Uint8List.fromList(hash.bytes);

      // Decode base64url components
      final nBytes = _base64UrlDecode(n);
      final dBytes = _base64UrlDecode(d);
      final pBytes = _base64UrlDecode(p);
      final qBytes = _base64UrlDecode(q);
      final dpBytes = _base64UrlDecode(dp);
      final dqBytes = _base64UrlDecode(dq);
      final qiBytes = _base64UrlDecode(qi);

      // Create RSA private key BigInts
      final nBigInt = _bytesToBigInt(nBytes);
      final dBigInt = _bytesToBigInt(dBytes);
      final pBigInt = _bytesToBigInt(pBytes);
      final qBigInt = _bytesToBigInt(qBytes);
      final dpBigInt = _bytesToBigInt(dpBytes);
      final dqBigInt = _bytesToBigInt(dqBytes);
      final qiBigInt = _bytesToBigInt(qiBytes);

      // Create RSA private key
      final rsaParams = crypto.RSAPrivateKey(nBigInt, dBigInt);
      rsaParams.p = pBigInt;
      rsaParams.q = qBigInt;
      rsaParams.dP = dpBigInt;
      rsaParams.dQ = dqBigInt;
      rsaParams.qInv = qiBigInt;

      // Create signer with RSA-PSS
      final signer = crypto.PSSSigner(
        crypto.RSASigner()
          ..init(true, crypto.PrivateKeyParameter<crypto.RSAPrivateKey>(rsaParams)),
      )..init(true, crypto.PrivateKeyParameter<crypto.RSAPrivateKey>(rsaParams));

      // Sign the hash
      signer.reset();
      signer.update(hashBytes);
      final signature = signer.generateSignature() as crypto.Signature;

      return Uint8List.fromList(signature.bytes);
    } catch (e) {
      // If signing fails, throw a helpful error
      throw Exception(
        'RSA signing failed: $e\n'
        'Note: For production use, please integrate a proper Arweave SDK.\n'
        'Recommended: arweave-dart package from GitHub (CDDelta/arweave-dart)',
      );
    }
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

  /// Convert bytes to BigInt
  crypto.BigInt _bytesToBigInt(Uint8List bytes) {
    crypto.BigInt result = crypto.BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = result * crypto.BigInt.from(256) + crypto.BigInt.from(bytes[i]);
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

