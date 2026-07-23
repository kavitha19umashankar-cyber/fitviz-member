import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitviz_member/shared/widgets/formatted_plan_text.dart';

void main() {
  const baseStyle = TextStyle(color: Colors.white, fontSize: 14, height: 1.4);

  Future<void> pump(WidgetTester tester, String raw) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FormattedPlanLine(raw: raw, baseStyle: baseStyle),
      ),
    ));
  }

  testWidgets('renders <title> as uppercase orange bold text', (tester) async {
    await pump(tester, '<title>Biceps</title>');

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'BICEPS');
    expect(text.style!.color, const Color(0xFFFF7A1A));
    expect(text.style!.fontWeight, FontWeight.bold);
  });

  testWidgets('renders <bullet> line with a leading bullet glyph', (tester) async {
    await pump(tester, '<bullet>Spider Curls (DB) – 15 x 4</bullet>');

    expect(find.textContaining('•'), findsOneWidget);
    expect(find.textContaining('Spider Curls (DB)'), findsOneWidget);
  });

  testWidgets('renders nested <b> inside <bullet>', (tester) async {
    await pump(tester, '<bullet><b>Spider Curls</b> (DB) – 15 x 4</bullet>');

    final richText = tester.widget<Text>(
      find.descendant(of: find.byType(Expanded), matching: find.byType(Text)),
    );
    final span = richText.textSpan as TextSpan;
    final boldSpan = span.children!.firstWhere(
      (s) => (s as TextSpan).text == 'Spider Curls',
    ) as TextSpan;
    expect(boldSpan.style!.fontWeight, FontWeight.bold);
  });

  testWidgets('plain untagged line renders unchanged', (tester) async {
    await pump(tester, '🔥 Train Hard • Stay Consistent • Every Rep Counts');

    expect(
      find.text('🔥 Train Hard • Stay Consistent • Every Rep Counts'),
      findsOneWidget,
    );
  });

  testWidgets('malformed tags fall back to stripped plain text without throwing',
      (tester) async {
    await pump(tester, '<title>Unclosed title');

    expect(tester.takeException(), isNull);
  });
}
