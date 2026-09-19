import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:greenlight/main.dart';
import 'package:greenlight/widgets/comic_button.dart';
import 'package:greenlight/widgets/comic_icon_button.dart';

void main() {
  testWidgets(
    'shows the home screen with the best reaction and start button',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const GreenlightApp());
      // Let the splash screen's 2s loading animation finish, hand off to
      // HomeScreen, and let its high-score-loading future resolve.
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Greenlight'), findsOneWidget);
      expect(find.text('BEST REACTION'), findsOneWidget);
      expect(find.widgetWithText(ComicButton, 'Start Match'), findsOneWidget);
      // Leaderboard/Tuto/Influencer Mode/Settings are icon-only, top row.
      expect(find.byType(ComicIconButton), findsNWidgets(4));
    },
  );
}
