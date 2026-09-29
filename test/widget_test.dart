import 'package:askia_kost_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens directly to login before any home content is reachable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AskiaKostApp());
    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pumpAndSettle();

    // App must land on the login/register gate first, not the home page.
    expect(find.text('Masuk ke Askia Kos'), findsOneWidget);
    expect(find.text('Pembeli'), findsOneWidget);
    expect(find.text('Penjual'), findsOneWidget);
    expect(find.textContaining('Admin'), findsNothing);

    // No shortcut around the gate: home content isn't reachable pre-login.
    expect(find.text('askia kos'), findsNothing);
    expect(find.text('Cari Rekomendasi Sesuai Preferensimu'), findsNothing);

    // The initial gate has nothing to close back to.
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}
