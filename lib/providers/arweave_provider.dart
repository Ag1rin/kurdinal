import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/arweave_service.dart';

/// Provider for Arweave service
final arweaveServiceProvider = Provider<ArweaveService>((ref) {
  return ArweaveService();
});

/// Provider for wallet loading status
final walletStatusProvider = StateProvider<WalletStatus>((ref) => WalletStatus.notLoaded);

enum WalletStatus {
  notLoaded,
  loading,
  loaded,
  error,
}

