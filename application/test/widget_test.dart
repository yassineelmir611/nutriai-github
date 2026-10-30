// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:nutriai/main.dart';
import 'package:nutriai/data/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveTestDirectory;

  setUpAll(() async {
    hiveTestDirectory = await Directory.systemTemp.createTemp('nutriai_test_');
    Hive.init(hiveTestDirectory.path);
    await LocalStorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveTestDirectory.existsSync()) {
      hiveTestDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('NutriAI app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NutriAiApp()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NutriAiApp), findsOneWidget);
  });
}
