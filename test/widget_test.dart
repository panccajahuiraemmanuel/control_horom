import 'package:flutter_test/flutter_test.dart';
import 'package:control_horom/main.dart';

void main() {
  testWidgets('Carga inicial de MINA-OPS', (WidgetTester tester) async {
    await tester.pumpWidget(const MinaHorometrosApp());
    expect(find.text('MINA-OPS'), findsOneWidget);
  });
}
