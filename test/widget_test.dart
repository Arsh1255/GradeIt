import 'package:flutter_test/flutter_test.dart';
import 'package:grade_it/main.dart';
import 'package:grade_it/screens/dashboard_screen.dart';

void main() {
  testWidgets('GradeIt App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GradeItApp());

    // Verify that we load the dashboard and not a crash screen.
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
