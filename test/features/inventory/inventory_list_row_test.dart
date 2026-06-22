import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository.dart';
import 'package:v2mem_clinic/features/inventory/inventory_list_screen.dart';
import 'package:v2mem_clinic/features/inventory/widgets/inventory_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('inventory list uses clinical rows and legend', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doc',
        role: AppRoles.doctor,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const InventoryListScreen(),
        ),
        GoRoute(
          path: '/inventory/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Inventory ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryClinicalListRow), findsWidgets);
    expect(find.byType(ClinicalSeparatedListBody), findsWidgets);
    expect(find.text('Durum renkleri'), findsOneWidget);

    await tester.tap(find.byType(InventoryClinicalListRow).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Inventory'), findsOneWidget);
  });

  testWidgets('low stock item shows alert chip', (tester) async {
    final item = InventoryRepository.instance.getAll().firstWhere(
          InventoryRepository.isLowStock,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryClinicalListRow(
            item: item,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(StatusChip), findsOneWidget);
    expect(find.text('Düşük stok'), findsOneWidget);
  });
}
