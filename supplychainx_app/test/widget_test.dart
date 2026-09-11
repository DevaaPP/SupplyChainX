import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplychainx_app/features/product/domain/product_model.dart';
import 'package:supplychainx_app/core/rbac/roles.dart';

void main() {
  test('SupplyChainX models and mock data initialize correctly', () {
    final products = ProductModel.mockProducts();
    expect(products.isNotEmpty, true);
    expect(products.first.id, 'SCX-00112');
    expect(products.first.isAuthentic, true);
    expect(UserRole.values.length, 5);
  });
}
