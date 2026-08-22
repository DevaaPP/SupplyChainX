import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplychainx_app/app.dart';

void main() {
  testWidgets('App loads successfully smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SupplyChainXApp(),
      ),
    );
    expect(find.byType(SupplyChainXApp), findsOneWidget);
  });
}
