// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_recommendation_app/src/app.dart';

void main() {
  testWidgets('App starts and renders a scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const AnimeRecommendationApp());
    await tester.pump(const Duration(milliseconds: 500));

    // At minimum, ensure the app renders its main scaffold structure.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
