import 'package:flutter_test/flutter_test.dart';
import 'package:officebuddy/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const OfficeBuddyApp());
    expect(find.byType(OfficeBuddyApp), findsOneWidget);
  });
}
