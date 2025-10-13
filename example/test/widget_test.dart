// This is a basic Flutter widget test for the itsi_map example app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsi_map/itsi_map.dart';

import 'package:itsi_map_example/main.dart';

void main() {
  testWidgets('App should build and show map page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title appears in the AppBar
    expect(find.text('itsi_map 예제'), findsOneWidget);

    // Verify that floating action buttons are present
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  testWidgets('GPS coordinates button should exist', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that GPS button exists
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });
}
