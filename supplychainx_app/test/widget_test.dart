import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplychainx_app/features/product/domain/product_model.dart';
import 'package:supplychainx_app/core/rbac/roles.dart';

void main() {
  test('SupplyChainX models and showcase templates initialize correctly', () {
    final templates = ProductModel.showcaseTemplates();
    expect(templates.isNotEmpty, true);
    expect(templates.length >= 4, true);
    expect(templates.first['key'], 'tea');

    final products = ProductModel.mockProducts();
    expect(products.isEmpty, true);
    expect(UserRole.values.length, 5);
  });
}
