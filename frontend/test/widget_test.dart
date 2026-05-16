import 'package:flutter_test/flutter_test.dart';
import 'package:blind_assist_ai/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const BlindAssistApp());
    expect(find.text('Blind Assist AI'), findsOneWidget);
  });
}
