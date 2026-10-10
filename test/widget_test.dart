import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lantern/app/theme.dart';
import 'package:lantern/core/sync/outbox_sync_engine.dart';
import 'package:lantern/features/home/presentation/home_screen.dart';
import 'package:lantern/features/incidents/presentation/incidents_history_screen.dart';
import 'package:lantern/features/safety_guide/presentation/safety_guide_screen.dart';
import 'package:lantern/features/settings/presentation/settings_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HomeScreen mounts correctly with brand and telemetry', (WidgetTester tester) async {
    final syncEngine = OutboxSyncEngine();

    await tester.pumpWidget(
      MaterialApp(
        theme: LanternTheme.darkTheme,
        home: HomeScreen(
          syncEngine: syncEngine,
          onNavigateTab: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('LANTERN'), findsWidgets);
    expect(find.text('Ready to help'), findsOneWidget);
    expect(find.text('You are not alone'), findsOneWidget);
    expect(find.text('Help is just one tap away'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Emergency\nCall'), findsOneWidget);
    expect(find.text('Find\nShelter'), findsOneWidget);
  });

  testWidgets('IncidentsHistoryScreen mounts and displays header and sync action', (WidgetTester tester) async {
    final syncEngine = OutboxSyncEngine();

    await tester.pumpWidget(
      MaterialApp(
        theme: LanternTheme.darkTheme,
        home: IncidentsHistoryScreen(syncEngine: syncEngine),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('My Incidents'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
  });

  testWidgets('SafetyGuideScreen mounts and renders disaster protocol cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LanternTheme.darkTheme,
        home: const SafetyGuideScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Safety Guide'), findsOneWidget);
    expect(find.text('Earthquake'), findsOneWidget);
    expect(find.text('Flood'), findsOneWidget);
    expect(find.text('Fire'), findsOneWidget);
  });

  testWidgets('SettingsScreen mounts and displays profile and settings options', (WidgetTester tester) async {
    final syncEngine = OutboxSyncEngine();

    await tester.pumpWidget(
      MaterialApp(
        theme: LanternTheme.darkTheme,
        home: SettingsScreen(syncEngine: syncEngine),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('LANTERN User'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('My Statistics'), findsOneWidget);
    expect(find.text('Emergency Contacts'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);
  });
}
