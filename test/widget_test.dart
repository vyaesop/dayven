import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vertical_planner/app/app.dart';

void main() {
  testWidgets('planner home screen renders primary chrome', (tester) async {
    SharedPreferences.setMockInitialValues({
      'storage_mode': 'cloud_sync',
      // Skip the first-run welcome tour so the home screen is in front.
      'has_seen_welcome_v1': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: DayvenApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Stable chrome that is always present regardless of the current date.
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('SCHEDULE'), findsOneWidget);
    // The always-available create-event action.
    expect(find.byTooltip('New event'), findsOneWidget);
  });
}
