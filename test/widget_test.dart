import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';

void main() {
  testWidgets('shows the React home shell', (tester) async {
    await tester.pumpWidget(const ReactApp());
    await tester.pump();

    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('MODES'), findsOneWidget);
    expect(find.text('DAILY'), findsOneWidget);
    expect(find.text('SCORES'), findsOneWidget);
  });
}
