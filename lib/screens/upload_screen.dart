import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/kurdish_word.dart';
import '../providers/arweave_provider.dart';
import '../services/storage_service.dart';
import '../utils/error_handler.dart';

/// Screen for uploading words to Arweave
class UploadScreen extends ConsumerStatefulWidget {
  final List<KurdishWord> words;

  const UploadScreen({super.key, required this.words});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  bool _isUploading = false;
  String? _transactionId;
  String? _viewUrl;
  String? _error;
  String? _progressMessage;
  String? _walletBalance;

  Future<void> _loadWallet() async {
    try {
      ref.read(walletStatusProvider.notifier).state = WalletStatus.loading;
      setState(() {
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Arweave Wallet (JWK)',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        final arweaveService = ref.read(arweaveServiceProvider);
        await arweaveService.loadWalletFromFile(file);

        // Load balance
        final balance = await arweaveService.getWalletBalance();
        
        ref.read(walletStatusProvider.notifier).state = WalletStatus.loaded;
        setState(() {
          _walletBalance = balance;
        });
      } else {
        ref.read(walletStatusProvider.notifier).state = WalletStatus.notLoaded;
        setState(() {
        });
      }
    } catch (e) {
      ref.read(walletStatusProvider.notifier).state = WalletStatus.error;
      setState(() {
        _error = e.toString();
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _uploadToArweave() async {
    final arweaveService = ref.read(arweaveServiceProvider);
    
    if (!arweaveService.isWalletLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load your wallet first')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
      _progressMessage = 'Checking wallet balance...';
    });

    try {
      // Format data as JSON
      String jsonData;
      if (widget.words.length == 1) {
        jsonData = jsonEncode(widget.words.first.toJson());
      } else {
        jsonData = jsonEncode(widget.words.map((w) => w.toJson()).toList());
      }

      // Check balance before uploading
      final dataSize = jsonData.length;
      final hasBalance = await arweaveService.hasSufficientBalance(dataSize);
      
      if (!hasBalance) {
        final balance = await arweaveService.getWalletBalance();
        setState(() {
          _isUploading = false;
          _progressMessage = null;
          _error = 'Insufficient balance. Current balance: ${balance ?? "Unknown"} AR';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient balance. Current: ${balance ?? "Unknown"} AR'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create tags
      final tags = {
        'Content-Type': 'application/json',
        'App-Name': 'KurdishWords',
        'Language': 'Kurdish',
        'Version': '1.0.0',
      };

      // Upload
      final result = await arweaveService.uploadToArweave(
        data: jsonData,
        tags: tags,
        onProgress: (progress) {
          setState(() {
            _progressMessage = progress;
          });
        },
      );

      setState(() {
        _isUploading = false;
        _progressMessage = null;
        if (result.success) {
          _transactionId = result.transactionId;
          _viewUrl = result.viewUrl;
          
          // Save transaction to history
          final storageService = StorageService();
          storageService.saveTransaction(
            transactionId: result.transactionId!,
            viewUrl: result.viewUrl!,
            wordCount: widget.words.length,
            timestamp: DateTime.now(),
          );
        } else {
          _error = result.error;
        }
      });

      if (result.success) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _progressMessage = null;
        _error = e.toString();
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: ErrorHandler.isRetryable(e)
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: _uploadToArweave,
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletStatus = ref.watch(walletStatusProvider);
    final arweaveService = ref.read(arweaveServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload to Arweave'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Words to upload: ${widget.words.length}'),
                    const SizedBox(height: 8),
                    Text('Data size: ~${_estimateSize()} bytes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Wallet Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (walletStatus == WalletStatus.loaded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Wallet Loaded',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Address: ${arweaveService.getWalletAddress() ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (_walletBalance != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Balance: $_walletBalance AR',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _loadWallet,
                        icon: const Icon(Icons.wallet),
                        label: const Text('Load Wallet (JWK)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isUploading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _progressMessage ?? 'Uploading to Arweave...',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (_transactionId != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Upload Successful!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Transaction ID:'),
                      SelectableText(
                        _transactionId!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_viewUrl != null) ...[
                        const Text('View on Arweave:'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse(_viewUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open $uri')),
                                );
                              }
                            }
                          },
                          child: Text(
                            _viewUrl!,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            if (walletStatus == WalletStatus.loaded && !_isUploading && _transactionId == null)
              ElevatedButton(
                onPressed: _uploadToArweave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Upload to Arweave',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(height: 8),
                  Text(
                    'Warning: Once uploaded, this data is permanent and immutable on Arweave. It cannot be edited or deleted.',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _estimateSize() {
    final jsonString = jsonEncode(widget.words.map((w) => w.toJson()).toList());
    return utf8.encode(jsonString).length;
  }
}

