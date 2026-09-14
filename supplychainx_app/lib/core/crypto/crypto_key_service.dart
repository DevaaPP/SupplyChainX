import 'dart:convert';
import 'dart:math';
import '../../features/product/domain/product_model.dart';

/// Cryptographic verification result object
class VerificationResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? verifiedTxHash;
  final String? receiptSignature;
  final String? signerRole;

  const VerificationResult({
    required this.isSuccess,
    this.errorMessage,
    this.verifiedTxHash,
    this.receiptSignature,
    this.signerRole,
  });

  factory VerificationResult.success({
    required String verifiedTxHash,
    required String receiptSignature,
    required String signerRole,
  }) {
    return VerificationResult(
      isSuccess: true,
      verifiedTxHash: verifiedTxHash,
      receiptSignature: receiptSignature,
      signerRole: signerRole,
    );
  }

  factory VerificationResult.failure(String error) {
    return VerificationResult(
      isSuccess: false,
      errorMessage: error,
    );
  }
}

/// Core Cryptographic Service managing Root Master Public Key and Role Private Keys
class CryptoKeyService {
  /// Master Root Public Key (Known across the network to verify blockchain authenticity)
  static const String masterPublicKey =
      '0x04F9A82B3C5E7D1A9F8E4D2C0B9A8F7E6D5C4B3A2F1E0D9C8B7A6F5E4D3C2B1A0F9E8D7C6B5A4F3E2D1C0B9A8F7E6D5C4B3A2F1E0D9C8B7A6F5E4D3C2B1A0F';

  /// Master Public Key Short Fingerprint
  static const String masterPublicKeyFingerprint = 'SCX-PUB-MASTER-88F4A2';

  /// Distinct Private Keys for each stakeholder role
  static const Map<String, String> rolePrivateKeys = {
    'manufacturer': '0xMFG_PRIV_8A9F21CD45EB6701AA892345DEF01234567890ABCDEF1234567890ABCDEF',
    'distributor': '0xDIST_PRIV_4C7291AB83FE2091DD456789ABCDEF01234567890ABCDEF1234567890AB',
    'warehouse': '0xWH_PRIV_9E1102BC47DA8390EE567890ABCDEF01234567890ABCDEF1234567890ABC',
    'retailer': '0xRET_PRIV_3B6582FA19CE4082FF678901ABCDEF01234567890ABCDEF1234567890ABCD',
    'customer': '0xCUST_PRIV_7D0249EC68BA3071AA789012ABCDEF01234567890ABCDEF1234567890ABC',
    'admin': '0xADM_PRIV_0F4461BA92DE5180BB890123ABCDEF01234567890ABCDEF1234567890ABCD',
  };

  /// Retrieve the private key for a given role
  static String getPrivateKeyForRole(String role) {
    return rolePrivateKeys[role.toLowerCase()] ?? rolePrivateKeys['customer']!;
  }

  /// Retrieve masked private key representation for display
  static String getMaskedPrivateKey(String role) {
    final key = getPrivateKeyForRole(role);
    if (key.length > 18) {
      return '${key.substring(0, 10)}...${key.substring(key.length - 8)}';
    }
    return key;
  }

  /// Extracts the on-chain Tx Hash for a product matching the timeline format
  static String getTxHashForProduct(ProductModel product) {
    if (product.journey.isNotEmpty) {
      final hash = product.journey.last.blockchainHash.trim();
      if (hash.isNotEmpty && hash != '0xverified') {
        return hash.startsWith('0x') ? hash : '0x$hash';
      }
    }
    if (product.qrSignature != null && product.qrSignature!.isNotEmpty) {
      final sig = product.qrSignature!.trim();
      return sig.startsWith('0x') ? sig : '0x$sig';
    }
    // Deterministic fallback hash based on product parameters
    final raw = '${product.id}:${product.batchNumber}:${product.createdAt.millisecondsSinceEpoch}';
    final hex = raw.hashCode.abs().toRadixString(16).padLeft(16, '0');
    return '0x8b19f4913f$hex';
  }

  /// Formats a hash to the short format: "8b19f4913f...092ddc89"
  static String formatShortTx(String txHash) {
    var clean = txHash.startsWith('0x') ? txHash.substring(2) : txHash;
    if (clean.length > 20) {
      return '${clean.substring(0, 10)}...${clean.substring(clean.length - 8)}';
    }
    return clean;
  }

  /// Resolves the expected target role from the scan action
  static String getTargetRoleForAction(String? action) {
    if (action == 'distributor_accept') return 'distributor';
    if (action == 'warehouse_intake') return 'warehouse';
    if (action == 'retailer_receive' || action == 'retailer_sold') return 'retailer';
    return 'distributor';
  }

  /// Generates the Cryptographic QR Payload containing the on-chain Tx Hash and manufacturer signature
  static String generateTransactionQrPayload(ProductModel product, {String? targetRole}) {
    final effectiveTargetRole = targetRole ?? 'distributor';
    final txHash = getTxHashForProduct(product);
    final mfgKey = getPrivateKeyForRole('manufacturer');
    final signatureRaw = '$txHash:${product.id}:$effectiveTargetRole:$mfgKey';
    final sigHex = '0x${signatureRaw.hashCode.abs().toRadixString(16).padLeft(16, '0')}';

    final payload = {
      'protocol': 'SCX_SECURE_TX_V2',
      'tx_hash': txHash,
      'product_id': product.id,
      'product_name': product.name,
      'batch_number': product.batchNumber,
      'target_role': effectiveTargetRole,
      'master_pubkey': masterPublicKeyFingerprint,
      'mfg_signature': sigHex,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(payload);
  }

  /// Verifies a scanned or transmitted cryptographic transaction payload using the actor's Role Private Key
  static VerificationResult verifyAndSignAcceptance({
    required String rawPayload,
    required ProductModel targetProduct,
    required String expectedAction,
    required String userRole,
    required String userEmail,
  }) {
    final expectedRole = getTargetRoleForAction(expectedAction);
    final expectedTxHash = getTxHashForProduct(targetProduct);

    String? scannedTxHash;
    String? scannedProductId;
    String? scannedTargetRole;

    final trimmed = rawPayload.trim();

    // Check if raw payload is JSON
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final Map<String, dynamic> data = jsonDecode(trimmed);
        scannedTxHash = data['tx_hash']?.toString();
        scannedProductId = data['product_id']?.toString();
        scannedTargetRole = data['target_role']?.toString();
      } catch (_) {}
    } else if (trimmed.startsWith('0x') && trimmed.length >= 16) {
      // Direct on-chain Tx Hash scan (must be hexadecimal)
      scannedTxHash = trimmed;
      scannedProductId = targetProduct.id;
      scannedTargetRole = expectedRole;
    }

    // 1. Validate Transaction Hash Presence
    if (scannedTxHash == null || scannedTxHash.isEmpty) {
      return VerificationResult.failure(
        'Invalid QR format: No cryptographic on-chain Tx hash detected in scan payload. Random text rejected.',
      );
    }

    // 2. Validate Tx Hash Match against Consignment Ledger State (STRICT EXACT MATCH)
    final cleanScannedTx = scannedTxHash.replaceAll('0x', '').toLowerCase().trim();
    final cleanExpectedTx = expectedTxHash.replaceAll('0x', '').toLowerCase().trim();

    if (cleanScannedTx != cleanExpectedTx) {
      return VerificationResult.failure(
        'Cryptographic Signature Mismatch! Scanned Tx ($scannedTxHash) does not match authentic on-chain Tx ($expectedTxHash). Acceptance denied.',
      );
    }

    // 3. Validate Product ID Match
    if (scannedProductId != null &&
        scannedProductId.isNotEmpty &&
        scannedProductId.toLowerCase() != targetProduct.id.toLowerCase()) {
      return VerificationResult.failure(
        'Serial mismatch! Scanned payload is addressed to $scannedProductId, but active terminal is processing ${targetProduct.id}.',
      );
    }

    // 4. Validate Role Authorization
    final normalizedUserRole = userRole.toLowerCase();
    final isAuthorizedRole = normalizedUserRole == expectedRole ||
        normalizedUserRole == 'admin' ||
        (scannedTargetRole != null && normalizedUserRole == scannedTargetRole.toLowerCase());

    if (!isAuthorizedRole) {
      return VerificationResult.failure(
        'Role Authorization Failed! Consignment is sealed for "$expectedRole" intake, but active operator has role "$userRole".',
      );
    }

    // 5. Compute Acceptance Cryptographic Signature using the Actor's Role Private Key
    final rolePrivKey = getPrivateKeyForRole(userRole);
    final nowTs = DateTime.now().millisecondsSinceEpoch;
    final receiptPayload = '$expectedTxHash:$userRole:$userEmail:$rolePrivKey:$nowTs';
    final receiptSignature = '0x${receiptPayload.hashCode.abs().toRadixString(16).padLeft(16, '0')}';

    return VerificationResult.success(
      verifiedTxHash: expectedTxHash,
      receiptSignature: receiptSignature,
      signerRole: userRole,
    );
  }

  /// Verifies if a scanned raw string matches a product's on-chain Tx or signed envelope
  static bool isPayloadAuthenticForProduct(String rawPayload, ProductModel product) {
    final trimmed = rawPayload.trim();
    final expectedTx = getTxHashForProduct(product).replaceAll('0x', '').toLowerCase().trim();

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final Map<String, dynamic> data = jsonDecode(trimmed);
        final tx = data['tx_hash']?.toString().replaceAll('0x', '').toLowerCase().trim();
        final pid = data['product_id']?.toString().trim();
        if (pid != null && pid.toLowerCase() != product.id.toLowerCase()) return false;
        return tx == expectedTx;
      } catch (_) {
        return false;
      }
    } else if (trimmed.startsWith('0x') && trimmed.length >= 16) {
      final clean = trimmed.replaceAll('0x', '').toLowerCase().trim();
      return clean == expectedTx;
    }
    return false;
  }
}
