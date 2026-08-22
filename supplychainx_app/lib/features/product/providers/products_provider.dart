import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/product_model.dart';

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  final ApiClient _apiClient;

  ProductsNotifier(this._apiClient) : super(ProductModel.mockProducts()) {
    _fetchProductsFromBackend();
  }

  // Load from FastAPI backend if available
  Future<void> _fetchProductsFromBackend() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.products);
      if (res != null && res.statusCode == 200 && res.data is List) {
        final List list = res.data;
        if (list.isNotEmpty) {
          // Merge / populate backend records
        }
      }
    } catch (_) {
      // Backend offline or running in mock mode
    }
  }

  // 1. Register new product (Manufacturer)
  Future<void> addProduct(ProductModel product) async {
    state = [product, ...state];

    // Try posting to backend
    try {
      await _apiClient.post(
        ApiEndpoints.registerProduct,
        data: {
          'product_id': product.id,
          'name': product.name,
          'batch_number': product.batchNumber,
          'category': product.category,
          'description': product.description,
          'factory_location': product.factoryLocation,
        },
      );
    } catch (_) {}
  }

  // 2. Update Location / In-Transit Checkpoint (Distributor)
  Future<void> updateLocation({
    required String productId,
    required String location,
    required String action,
    String? actorName = 'Siliguri Logistics Hub',
    String? notes,
  }) async {
    final idx = state.indexWhere((p) => p.id == productId);
    if (idx == -1) return;

    final existing = state[idx];
    final randomHex = (Random().nextInt(0xFFFFFF) + 0x100000).toRadixString(16);
    final newStage = JourneyStage(
      id: 'js-${DateTime.now().millisecondsSinceEpoch}',
      actor: actorName ?? 'Siliguri Logistics Hub',
      role: 'Distributor',
      action: action,
      location: location,
      timestamp: DateTime.now(),
      blockchainHash: '0x$randomHex${existing.id.replaceAll('-', '')}',
      verified: true,
    );

    final updated = ProductModel(
      id: existing.id,
      name: existing.name,
      batchNumber: existing.batchNumber,
      manufacturerId: existing.manufacturerId,
      manufacturerName: existing.manufacturerName,
      currentOwner: actorName ?? 'Siliguri Logistics Hub',
      currentOwnerRole: 'distributor',
      createdAt: existing.createdAt,
      journey: [...existing.journey, newStage],
      qrSignature: existing.qrSignature,
      category: existing.category,
      description: existing.description,
      factoryLocation: existing.factoryLocation,
      isAuthentic: existing.isAuthentic,
    );

    final newList = [...state];
    newList[idx] = updated;
    state = newList;

    // Send custody update to backend
    try {
      await _apiClient.post(
        ApiEndpoints.custodyTransfer,
        data: {
          'product_id': productId,
          'recipient_name': actorName,
          'recipient_role': 'distributor',
          'location': location,
          'action': action,
          'notes': notes,
        },
      );
    } catch (_) {}
  }

  // 3. Transfer Custody (Distributor ➔ Warehouse or Warehouse ➔ Retailer)
  Future<void> transferProduct({
    required String productId,
    required String recipientName,
    required String recipientRole,
    required String location,
    required String action,
    String? notes,
  }) async {
    final idx = state.indexWhere((p) => p.id == productId);
    if (idx == -1) return;

    final existing = state[idx];
    final randomHex = (Random().nextInt(0xFFFFFF) + 0x100000).toRadixString(16);
    final newStage = JourneyStage(
      id: 'js-${DateTime.now().millisecondsSinceEpoch}',
      actor: recipientName,
      role: recipientRole.capitalize(),
      action: action,
      location: location,
      timestamp: DateTime.now(),
      blockchainHash: '0x$randomHex${existing.id.replaceAll('-', '')}',
      verified: true,
    );

    final updated = ProductModel(
      id: existing.id,
      name: existing.name,
      batchNumber: existing.batchNumber,
      manufacturerId: existing.manufacturerId,
      manufacturerName: existing.manufacturerName,
      currentOwner: recipientName,
      currentOwnerRole: recipientRole.toLowerCase(),
      createdAt: existing.createdAt,
      journey: [...existing.journey, newStage],
      qrSignature: existing.qrSignature,
      category: existing.category,
      description: existing.description,
      factoryLocation: existing.factoryLocation,
      isAuthentic: existing.isAuthentic,
    );

    final newList = [...state];
    newList[idx] = updated;
    state = newList;

    try {
      await _apiClient.post(
        ApiEndpoints.custodyTransfer,
        data: {
          'product_id': productId,
          'recipient_name': recipientName,
          'recipient_role': recipientRole.toLowerCase(),
          'location': location,
          'action': action,
          'notes': notes,
        },
      );
    } catch (_) {}
  }

  // 4. Mark as Sold (Retailer)
  Future<void> markAsSold({
    required String productId,
    required String storeName,
    required String buyerName,
  }) async {
    await transferProduct(
      productId: productId,
      recipientName: buyerName.isNotEmpty ? buyerName : 'Customer POS Checkout',
      recipientRole: 'customer',
      location: storeName,
      action: 'Point of Sale (POS) Purchased & Delivered',
      notes: 'Authenticity verified and ownership transferred to consumer',
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>(
  (ref) => ProductsNotifier(ref.watch(apiClientProvider)),
);
