import 'package:flutter_test/flutter_test.dart';
import 'package:react/app/react_app.dart';

void main() {
  testWidgets('shows the React home shell', (tester) async {
    await tester.pumpWidget(const ReactApp());

    expect(find.text('REACT'), findsOneWidget);
    expect(find.text('PLAY CLASSIC'), findsOneWidget);
  });
}
