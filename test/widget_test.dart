import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vertical_planner/app/app.dart';

void main() {
  testWidgets('planner home screen renders primary chrome', (tester) async {
    SharedPreferences.setMockInitialValues({
      'storage_mode': 'cloud_sync',
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: VerticalPlannerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('THURSDAY'), findsOneWidget);
    expect(find.text('Weekly stand-up'), findsOneWidget);
  });
}
