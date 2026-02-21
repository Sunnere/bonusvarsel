import 'package:flutter_test/flutter_test.dart';
import 'package:bonusvarsel/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const BonusvarselApp());
    expect(find.byType(BonusvarselApp), findsOneWidget);
  });
}
