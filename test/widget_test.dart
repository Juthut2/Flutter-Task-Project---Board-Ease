import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:rosalada_project_board_ease/app.dart';

void main() {
  testWidgets('shows BoardEase splash branding', (tester) async {
    await tester.pumpWidget(const BoardEaseApp());

    expect(find.text('BoardEase'), findsOneWidget);
    expect(find.byIcon(Icons.home_work_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
