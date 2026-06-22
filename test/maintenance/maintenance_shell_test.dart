import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/features/maintenance/widgets/maintenance_shell.dart';

void main() {
  testWidgets('MaintenanceShell has maintenance nav without clinical exit', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/maintenance',
          builder: (context, state) => const MaintenanceShell(
            title: 'Test',
            child: Text('body'),
          ),
        ),
      ],
      initialLocation: '/maintenance',
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Tanı'), findsOneWidget);
    expect(find.text('Klinikler'), findsOneWidget);
    expect(find.text('Yeni Klinik'), findsOneWidget);
    expect(find.text('İlk Yönetici'), findsOneWidget);
    expect(find.textContaining('bootstrap'), findsNothing);
    expect(find.byTooltip('Klinik uygulamasına dön'), findsNothing);
    expect(find.byIcon(Icons.exit_to_app), findsNothing);
  });
}
