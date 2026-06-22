import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/inventory/data/async_inventory_repository_contract.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_provider.dart';
import 'package:v2mem_clinic/features/inventory/inventory_list_screen.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_item.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_movement.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakeInventoryRepo implements AsyncInventoryRepositoryContract {
  final List<InventoryItem> _items;

  _FakeInventoryRepo(this._items);

  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async {
    var list = List<InventoryItem>.from(_items);
    if (lowStockOnly) {
      list = list.where((e) => e.currentQuantity <= e.minimumQuantity).toList();
    }
    return list;
  }

  @override
  Future<InventoryItem?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<InventoryItem> add(InventoryItem item) async {
    _items.insert(0, item);
    return item;
  }

  @override
  Future<InventoryItem> update(InventoryItem item) async => item;

  @override
  Future<String?> addMovement(InventoryMovement movement) async => null;

  @override
  Future<List<InventoryMovement>> getMovementsByItemId(
    String inventoryItemId,
  ) async =>
      [];

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

  testWidgets('nurse sees inventory list from async source', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );
    InventoryRepositoryProvider.resetCache();
    InventoryRepositoryProvider.testOverride = _FakeInventoryRepo([
      InventoryItem(
        id: 'inv-test-1',
        name: 'Test Eldiven',
        category: InventoryCategory.sarfMalzeme,
        unit: 'kutu',
        currentQuantity: 2,
        minimumQuantity: 5,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const InventoryListScreen(),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Test Eldiven'), findsWidgets);
    expect(find.textContaining('inv-test-1'), findsNothing);
    expect(find.textContaining('tenant_id'), findsNothing);
  });
}
