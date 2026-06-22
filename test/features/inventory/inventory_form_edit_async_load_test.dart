import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/inventory/data/async_inventory_repository_contract.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_provider.dart';
import 'package:v2mem_clinic/features/inventory/inventory_form_screen.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_item.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_movement.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeInventoryRepo implements AsyncInventoryRepositoryContract {
  final InventoryItem? editItem;

  _FakeInventoryRepo({this.editItem});

  @override
  Future<InventoryItem?> getById(String id) async => editItem;

  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async =>
      editItem == null ? const [] : [editItem!];

  @override
  Future<InventoryItem> add(InventoryItem item) async => item;

  @override
  Future<InventoryItem> update(InventoryItem item) async => item;

  @override
  Future<String?> addMovement(InventoryMovement movement) async => null;

  @override
  Future<List<InventoryMovement>> getMovementsByItemId(String inventoryItemId) async =>
      const [];

  @override
  Future<int> countLowStock() async => 0;

  @override
  Future<int> countExpiringSoon({int days = 30}) async => 0;

  @override
  Future<int> countExpired() async => 0;
}

void main() {
  tearDown(() {
    AuthSession.clear();
    InventoryRepositoryProvider.clearTestOverrides();
    InventoryRepositoryProvider.resetCache();
  });

  testWidgets('edit form loads item via async repository', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );

    InventoryRepositoryProvider.testOverride = _FakeInventoryRepo(
      editItem: InventoryItem(
        id: 'inv-edit-1',
        name: 'Remote Stok',
        category: InventoryCategory.ilac,
        unit: 'kutu',
        currentQuantity: 4,
        minimumQuantity: 2,
        isActive: true,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const InventoryFormScreen(inventoryId: 'inv-edit-1'),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Remote Stok'), findsOneWidget);
    expect(find.text('inv-edit-1'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
  });
}
