import 'package:flutter_test/flutter_test.dart';
import 'package:sportify/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpotifyCloneApp());

    // Verify that splash screen content is shown
    expect(find.text('Spotify'), findsOneWidget);
  });
}
