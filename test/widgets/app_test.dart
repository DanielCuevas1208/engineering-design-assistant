import 'package:engineering_design_assistant/src/db/in_memory_brief_repository.dart';
import 'package:engineering_design_assistant/src/sample/sample_brief.dart';
import 'package:engineering_design_assistant/src/store/brief_store.dart';
import 'package:engineering_design_assistant/src/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BriefStore> storeWithSample() async {
    final store = BriefStore(repository: InMemoryBriefRepository(SampleBrief.build()));
    await store.init();
    return store;
  }

  testWidgets('renders the shell and navigates between pages', (tester) async {
    final store = await storeWithSample();
    await tester.pumpWidget(EdaApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Compact linear actuator'), findsWidgets);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('8'), findsWidgets);

    await tester.tap(find.text('Requirements'));
    await tester.pumpAndSettle();
    expect(find.text('New requirement'), findsOneWidget);
    expect(
      find.textContaining('The mechanism shall provide a linear stroke'),
      findsOneWidget,
    );

    await tester.tap(find.text('Constraints'));
    await tester.pumpAndSettle();
    expect(find.text('New constraint'), findsOneWidget);
    expect(find.textContaining('Rated stall load'), findsOneWidget);

    await tester.tap(find.text('Validation'));
    await tester.pumpAndSettle();
    expect(find.text('Run again'), findsOneWidget);
    expect(find.textContaining('2 errors'), findsWidgets);
  });

  testWidgets('captures a requirement through the dialog', (tester) async {
    final store = await storeWithSample();
    await tester.pumpWidget(EdaApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Requirements'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New requirement'));
    await tester.pumpAndSettle();
    expect(find.text('New requirement'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'Shall use a sealed housing.');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Shall use a sealed housing'),
      findsOneWidget,
    );
    expect(store.requirementCount, 9);
  });

  testWidgets('exports the brief JSON from the brief page', (tester) async {
    final store = await storeWithSample();
    await tester.pumpWidget(EdaApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Brief'));
    await tester.pumpAndSettle();

    expect(find.text('Copy JSON'), findsOneWidget);
    expect(find.text('Export to file'), findsOneWidget);
    expect(
      find.textContaining('engineering-design-assistant/design-brief/1.0'),
      findsOneWidget,
    );
  });
}
