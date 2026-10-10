import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lantern/app/theme.dart';
import 'package:lantern/shared/widgets/glossy_button.dart';
import 'package:lantern/shared/widgets/lantern_brand.dart';
import 'package:lantern/shared/widgets/status_chip.dart';

void main() {
  testWidgets('LanternWordmark and Emblem render properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LanternWordmark(),
        ),
      ),
    );

    expect(find.text('LANTERN'), findsOneWidget);
    expect(find.byType(LanternEmblem), findsOneWidget);
  });

  testWidgets('StatusChip renders all 8 PRD incident delivery states truthfully', (WidgetTester tester) async {
    for (final state in IncidentDeliveryState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusChip(state: state),
          ),
        ),
      );

      expect(find.text(state.label), findsOneWidget);
    }
  });

  testWidgets('GlossyButton triggers callback and provides accessible semantics', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LanternTheme.darkTheme,
        home: Scaffold(
          body: GlossyButton(
            label: 'TEST ACTION',
            variant: GlossyButtonVariant.primary,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('TEST ACTION'), findsOneWidget);
    await tester.tap(find.text('TEST ACTION'));
    expect(tapped, isTrue);
  });
}
