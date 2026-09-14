import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplychainx_app/core/crypto/crypto_key_service.dart';
import 'package:supplychainx_app/features/product/domain/product_model.dart';

void main() {
  group('CryptoKeyService Tests', () {
    final mockProduct = ProductModel.fromJson({
      'id': 'SCX-00001',
      'name': 'Darjeeling First Flush Tea',
      'batch_number': 'BATCH-2024-001',
      'manufacturer_name': 'Himalayan Organic Tea Co.',
      'category': 'Beverages',
      'initial_location': 'Darjeeling Estate #4',
      'hmac_signature': '0x8b19f4913f9821a4b76e1092ddc89',
    });

    test('Master Public Key & Role Private Keys are configured', () {
      expect(CryptoKeyService.masterPublicKeyFingerprint, 'SCX-PUB-MASTER-88F4A2');
      expect(CryptoKeyService.getPrivateKeyForRole('manufacturer'), isNotEmpty);
      expect(CryptoKeyService.getPrivateKeyForRole('distributor'), isNotEmpty);
      expect(CryptoKeyService.getPrivateKeyForRole('warehouse'), isNotEmpty);
      expect(CryptoKeyService.getPrivateKeyForRole('retailer'), isNotEmpty);
      expect(CryptoKeyService.getPrivateKeyForRole('customer'), isNotEmpty);
    });

    test('Tx Hash Extraction & Short Formatting matches user requirements', () {
      final txHash = CryptoKeyService.getTxHashForProduct(mockProduct);
      expect(txHash, startsWith('0x8b19f4913f'));

      final shortTx = CryptoKeyService.formatShortTx(txHash);
      expect(shortTx, startsWith('8b19f4913f'));
      expect(shortTx, contains('...'));
    });

    test('generateTransactionQrPayload creates signed cryptographic payload', () {
      final payload = CryptoKeyService.generateTransactionQrPayload(
        mockProduct,
        targetRole: 'distributor',
      );

      final Map<String, dynamic> decoded = jsonDecode(payload);
      expect(decoded['protocol'], 'SCX_SECURE_TX_V2');
      expect(decoded['product_id'], mockProduct.id);
      expect(decoded['target_role'], 'distributor');
      expect(decoded['master_pubkey'], 'SCX-PUB-MASTER-88F4A2');
      expect(decoded['tx_hash'], startsWith('0x8b19f4913f'));
      expect(decoded['mfg_signature'], startsWith('0x'));
    });

    test('verifyAndSignAcceptance succeeds for authentic payload and matching role', () {
      final payload = CryptoKeyService.generateTransactionQrPayload(
        mockProduct,
        targetRole: 'distributor',
      );

      final result = CryptoKeyService.verifyAndSignAcceptance(
        rawPayload: payload,
        targetProduct: mockProduct,
        expectedAction: 'distributor_accept',
        userRole: 'distributor',
        userEmail: 'distributor@supplychainx.com',
      );

      expect(result.isSuccess, isTrue);
      expect(result.verifiedTxHash, mockProduct.journey.last.blockchainHash);
      expect(result.receiptSignature, startsWith('0x'));
      expect(result.signerRole, 'distributor');
    });

    test('verifyAndSignAcceptance rejects tampered / invalid Tx hash', () {
      final tamperedPayload = jsonEncode({
        'protocol': 'SCX_SECURE_TX_V2',
        'tx_hash': '0xDEADBEEF00000000000000000000',
        'product_id': mockProduct.id,
        'target_role': 'distributor',
      });

      final result = CryptoKeyService.verifyAndSignAcceptance(
        rawPayload: tamperedPayload,
        targetProduct: mockProduct,
        expectedAction: 'distributor_accept',
        userRole: 'distributor',
        userEmail: 'distributor@supplychainx.com',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Cryptographic Signature Mismatch'));
    });

    test('verifyAndSignAcceptance rejects unauthorized role', () {
      final payload = CryptoKeyService.generateTransactionQrPayload(
        mockProduct,
        targetRole: 'warehouse',
      );

      final result = CryptoKeyService.verifyAndSignAcceptance(
        rawPayload: payload,
        targetProduct: mockProduct,
        expectedAction: 'warehouse_intake',
        userRole: 'customer',
        userEmail: 'customer@supplychainx.com',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Role Authorization Failed'));
    });

    test('verifyAndSignAcceptance strictly rejects random characters / arbitrary text', () {
      final randomStrings = ['abc', 'random_chars', 'tea', '12345', '!@#\$%', 'Darjeeling', 'SCX-FAKE'];
      for (final str in randomStrings) {
        final result = CryptoKeyService.verifyAndSignAcceptance(
          rawPayload: str,
          targetProduct: mockProduct,
          expectedAction: 'distributor_accept',
          userRole: 'distributor',
          userEmail: 'distributor@supplychainx.com',
        );

        expect(result.isSuccess, isFalse, reason: 'Failed to reject random input: $str');
        expect(result.errorMessage, isNotNull);
      }
    });

    test('isPayloadAuthenticForProduct rejects random characters and accepts exact Tx', () {
      final validTx = CryptoKeyService.getTxHashForProduct(mockProduct);
      expect(CryptoKeyService.isPayloadAuthenticForProduct(validTx, mockProduct), isTrue);

      // Random strings must be rejected
      expect(CryptoKeyService.isPayloadAuthenticForProduct('abc', mockProduct), isFalse);
      expect(CryptoKeyService.isPayloadAuthenticForProduct('random123', mockProduct), isFalse);
      expect(CryptoKeyService.isPayloadAuthenticForProduct('tea', mockProduct), isFalse);
      expect(CryptoKeyService.isPayloadAuthenticForProduct('0x1234567890abcdef', mockProduct), isFalse);
    });
  });
}
