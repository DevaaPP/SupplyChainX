import '../../../core/rbac/roles.dart';

class JourneyStage {
  final String id;
  final String actor;
  final String role;
  final String action;
  final String location;
  final DateTime timestamp;
  final String blockchainHash;
  final bool verified;

  const JourneyStage({
    required this.id,
    required this.actor,
    required this.role,
    required this.action,
    required this.location,
    required this.timestamp,
    required this.blockchainHash,
    this.verified = true,
  });

  factory JourneyStage.fromJson(Map<String, dynamic> json) {
    return JourneyStage(
      id: json['id']?.toString() ?? 'stage-${DateTime.now().millisecondsSinceEpoch}',
      actor: json['actor_name']?.toString() ?? json['actor']?.toString() ?? 'Authorized Terminal',
      role: json['role']?.toString() ?? 'Participant',
      action: json['action']?.toString() ?? 'Transit Handover',
      location: json['location']?.toString() ?? 'Checkpoint Waypoint',
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      blockchainHash: json['block_hash']?.toString() ??
          json['blockchain_hash']?.toString() ??
          json['tx_hash']?.toString() ??
          '0xverified',
      verified: json['verified'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actor': actor,
        'role': role,
        'action': action,
        'location': location,
        'timestamp': timestamp.toIso8601String(),
        'blockchainHash': blockchainHash,
        'verified': verified,
      };
}

class ProductModel {
  final String id;
  final String name;
  final String batchNumber;
  final String manufacturerId;
  final String manufacturerName;
  final String currentOwner;
  final String currentOwnerRole;
  final DateTime createdAt;
  final List<JourneyStage> journey;
  final String? qrSignature;
  final String category;
  final String description;
  final String factoryLocation;
  final bool isAuthentic;

  const ProductModel({
    required this.id,
    required this.name,
    required this.batchNumber,
    required this.manufacturerId,
    required this.manufacturerName,
    required this.currentOwner,
    required this.currentOwnerRole,
    required this.createdAt,
    required this.journey,
    this.qrSignature,
    required this.category,
    required this.description,
    required this.factoryLocation,
    this.isAuthentic = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<JourneyStage> parsedJourney = [];
    if (json['journey'] is List) {
      parsedJourney = (json['journey'] as List)
          .map((item) => JourneyStage.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['blocks'] is List) {
      parsedJourney = (json['blocks'] as List)
          .map((item) => JourneyStage.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final pid = json['id']?.toString() ?? json['product_id']?.toString() ?? 'SCX-00000';
    final mfg = json['manufacturer_name']?.toString() ?? 'Guwahati Food Corp';
    final loc = json['factory_location']?.toString() ?? json['initial_location']?.toString() ?? 'Origin Facility';
    final hash = json['hmac_signature']?.toString() ?? json['product_hash']?.toString() ?? json['productHash']?.toString();

    if (parsedJourney.isEmpty) {
      parsedJourney = [
        JourneyStage(
          id: 'js-genesis-$pid',
          actor: mfg,
          role: 'Manufacturer',
          action: 'Batch Created & Cryptographic Genesis Block Sealed',
          location: loc,
          timestamp: json['created_at'] != null
              ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
              : DateTime.now(),
          blockchainHash: hash ?? '0xgenesis${pid.replaceAll('-', '')}',
          verified: true,
        ),
      ];
    }

    return ProductModel(
      id: pid,
      name: json['name']?.toString() ?? json['product_name']?.toString() ?? 'Consignment $pid',
      batchNumber: json['batch_number']?.toString() ?? json['batch']?.toString() ?? 'BAT-GENESIS',
      manufacturerId: json['manufacturer_id']?.toString() ?? 'usr-mfg',
      manufacturerName: mfg,
      currentOwner: json['current_owner_name']?.toString() ?? json['currentOwner']?.toString() ?? mfg,
      currentOwnerRole: json['current_role']?.toString() ?? json['role']?.toString() ?? 'manufacturer',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      journey: parsedJourney,
      qrSignature: hash,
      category: json['category']?.toString() ?? 'Logistics Consignment',
      description: json['description']?.toString() ?? 'Consignment committed to immutable ledger',
      factoryLocation: loc,
      isAuthentic: json['is_authentic'] as bool? ?? json['isValid'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'batch_number': batchNumber,
        'category': category,
        'description': description,
        'factory_location': factoryLocation,
        'manufacturer_id': manufacturerId,
        'manufacturer_name': manufacturerName,
        'current_owner_name': currentOwner,
        'current_role': currentOwnerRole,
        'is_authentic': isAuthentic,
        'created_at': createdAt.toIso8601String(),
        'journey': journey.map((j) => j.toJson()).toList(),
      };

  /// Clean slate: Returns an empty list so no fake demo products are shown by default.
  static List<ProductModel> mockProducts() => [];

  /// Real showcase product templates that can be provisioned with 1 click.
  static List<Map<String, String>> showcaseTemplates() => [
        {
          'key': 'tea',
          'name': 'Assam Organic Single-Estate Tea 250g',
          'category': 'Beverages',
          'description': 'First flush organic CTC & orthodox tea sourced from Brahmaputra valley estate.',
          'factory_location': 'Darjeeling Valley Facility',
          'badge': 'PREMIUM EXPORT',
        },
        {
          'key': 'pharma',
          'name': 'Cold-Chain Rapid Bio-Insulin 100IU',
          'category': 'Pharmaceuticals',
          'description': 'Cold-chain insulin medication verified with cryptographic batch hash and IoT sensor tracking.',
          'factory_location': 'Guwahati Bio-Pharma Cleanroom A',
          'badge': 'CRITICAL TEMP',
        },
        {
          'key': 'electronics',
          'name': 'Industrial IoT Telemetry Sensor Gateway',
          'category': 'Electronics',
          'description': 'Encrypted edge computing gateway for supply chain transit tracking and condition monitoring.',
          'factory_location': 'Northeast Microelectronics Assembly',
          'badge': 'HARDWARE CIPHER',
        },
        {
          'key': 'agriculture',
          'name': 'Organic Basmati Harvest 5kg',
          'category': 'Food & Agriculture',
          'description': 'Non-GMO premium aged organic basmati grain harvested and vacuum sealed for authenticity.',
          'factory_location': 'Brahmaputra Valley Organic Farm #3',
          'badge': 'AGRI-TRACE',
        },
      ];
}
