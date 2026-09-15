import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_endpoints.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiEndpoints.init();
  runApp(const ProviderScope(child: SupplyChainXApp()));
}
