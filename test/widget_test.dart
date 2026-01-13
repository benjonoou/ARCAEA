// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Music app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our music app loads with the bottom navigation
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify that the Home page loads by default
    expect(find.text('Home'), findsOneWidget);
    
    // Verify that the user's name appears on the home page
    expect(find.text('Lacrymira'), findsOneWidget);
  });

  testWidgets('Bottom navigation works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify we start on the Home page
    expect(find.text('Home'), findsOneWidget);

    // Tap the second navigation item (For You Page)
    await tester.tap(find.byIcon(Icons.music_note));
    await tester.pump();

    // Verify that we navigated to the For You page
    expect(find.text('For You Page'), findsOneWidget);

    // Tap the third navigation item (LLM Chat)
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pump();

    // Verify that we navigated to the LLM Chat page
    expect(find.text('LLM chat'), findsOneWidget);

    // Tap the fourth navigation item (Friends)
    await tester.tap(find.byIcon(Icons.people));
    await tester.pump();

    // Verify that we navigated to the Friends page
    expect(find.text('Friend'), findsOneWidget);
  });
}
