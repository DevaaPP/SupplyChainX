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

  static List<ProductModel> mockProducts() => [
        ProductModel(
          id: 'SCX-00112',
          name: 'Organic Rice 5kg',
          batchNumber: 'B-2024-001',
          manufacturerId: 'demo-mfg',
          manufacturerName: 'Rajesh Kumar',
          currentOwner: 'ABC Retail Store',
          currentOwnerRole: 'retailer',
          factoryLocation: 'Guwahati Factory',
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
          category: 'Food & Agriculture',
          description: 'Premium organic basmati rice, sourced from Punjab farms',
          qrSignature: 'hmac-sha256-valid-sig-abc123',
          isAuthentic: true,
          journey: [
            JourneyStage(
              id: 'js1',
              actor: 'XYZ Manufacturing',
              role: 'Manufacturer',
              action: 'Product Registered & QR Generated',
              location: 'Guwahati Factory',
              timestamp: DateTime.now().subtract(const Duration(days: 12)),
              blockchainHash: '0xabc123def456',
            ),
            JourneyStage(
              id: 'js2',
              actor: 'Fast Distributors',
              role: 'Distributor',
              action: 'Shipment Picked Up',
              location: 'Guwahati → Guwahati Warehouse',
              timestamp: DateTime.now().subtract(const Duration(days: 10)),
              blockchainHash: '0xdef456ghi789',
            ),
            JourneyStage(
              id: 'js3',
              actor: 'Central Warehouse',
              role: 'Warehouse',
              action: 'Stored & Quality Checked',
              location: 'Guwahati Warehouse',
              timestamp: DateTime.now().subtract(const Duration(days: 7)),
              blockchainHash: '0xghi789jkl012',
            ),
            JourneyStage(
              id: 'js4',
              actor: 'ABC Retail Store',
              role: 'Retailer',
              action: 'Delivered to Retailer — Pending Sale',
              location: 'ABC Retail Store',
              timestamp: DateTime.now().subtract(const Duration(days: 3)),
              blockchainHash: '0xjkl012mno345',
            ),
          ],
        ),
        ProductModel(
          id: 'SCX-00098',
          name: 'Darjeeling Tea 250g',
          batchNumber: 'B-2024-002',
          manufacturerId: 'demo-mfg',
          manufacturerName: 'Rajesh Kumar',
          currentOwner: 'Fast Distributors',
          currentOwnerRole: 'distributor',
          factoryLocation: 'Darjeeling Tea Estate',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          category: 'Beverages',
          description: 'First flush Darjeeling tea from certified organic estates',
          qrSignature: 'hmac-sha256-valid-sig-def456',
          isAuthentic: true,
          journey: [
            JourneyStage(
              id: 'js5',
              actor: 'XYZ Manufacturing',
              role: 'Manufacturer',
              action: 'Product Registered',
              location: 'Darjeeling Tea Estate',
              timestamp: DateTime.now().subtract(const Duration(days: 5)),
              blockchainHash: '0xpqr678stu901',
            ),
            JourneyStage(
              id: 'js6',
              actor: 'Fast Distributors',
              role: 'Distributor',
              action: 'In Transit',
              location: 'Siliguri Distribution Center',
              timestamp: DateTime.now().subtract(const Duration(days: 2)),
              blockchainHash: '0xvwx234yz5678',
            ),
          ],
        ),
        ProductModel(
          id: 'SCX-00134',
          name: 'Mango Pickle 500ml',
          batchNumber: 'B-2024-003',
          manufacturerId: 'demo-mfg',
          manufacturerName: 'Rajesh Kumar',
          currentOwner: 'Rajesh Kumar',
          currentOwnerRole: 'manufacturer',
          factoryLocation: 'Guwahati Factory',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          category: 'Food & Agriculture',
          description: 'Traditional raw mango pickle in mustard oil',
          isAuthentic: true,
          journey: [
            JourneyStage(
              id: 'js7',
              actor: 'XYZ Manufacturing',
              role: 'Manufacturer',
              action: 'Product Registered',
              location: 'Guwahati Factory',
              timestamp: DateTime.now().subtract(const Duration(hours: 3)),
              blockchainHash: '0xaaa111bbb222',
            ),
          ],
        ),
      ];
}
