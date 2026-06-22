import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/inventory/data/async_inventory_repository_contract.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_list_refresh.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_provider.dart';
import 'package:v2mem_clinic/features/inventory/inventory_list_screen.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_item.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_movement.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _MutableInventoryRepo implements AsyncInventoryRepositoryContract {
  final List<InventoryItem> items;
  int badgeReloadCount = 0;

  _MutableInventoryRepo(this.items);

  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async =>
      List.from(items);

  @override
  Future<InventoryItem?> getById(String id) async {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<InventoryItem> add(InventoryItem item) async {
    items.insert(0, item);
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
  Future<int> countLowStock() async {
    badgeReloadCount++;
    return badgeReloadCount;
  }

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

  testWidgets('inventory push return reloads list and badge when stale',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final items = [
      InventoryItem(
        id: 'inv-push-1',
        name: 'Başlangıç Sarf',
        category: InventoryCategory.sarfMalzeme,
        unit: 'adet',
        currentQuantity: 5,
        minimumQuantity: 2,
        isActive: true,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ),
    ];
    final repo = _MutableInventoryRepo(items);

    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );
    InventoryRepositoryProvider.resetCache();
    InventoryRepositoryProvider.testOverride = repo;

    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/inventory',
      routes: [
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryListScreen(),
        ),
        GoRoute(
          path: '/inventory/new',
          builder: (context, state) =>
              const Scaffold(body: Text('Stok Form Stub')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Başlangıç Sarf'), findsWidgets);
    expect(find.textContaining('Push Return Sarf'), findsNothing);
    final badgeLoadsBefore = repo.badgeReloadCount;

    await tester.tap(find.text('Yeni Stok Kartı'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    items.insert(
      0,
      InventoryItem(
        id: 'inv-push-2',
        name: 'Push Return Sarf',
        category: InventoryCategory.sarfMalzeme,
        unit: 'adet',
        currentQuantity: 1,
        minimumQuantity: 5,
        isActive: true,
        createdAt: DateTime(2026, 5, 2),
        updatedAt: DateTime(2026, 5, 2),
      ),
    );
    InventoryListRefresh.markStale();

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Push Return Sarf'), findsWidgets);
    expect(repo.badgeReloadCount, greaterThan(badgeLoadsBefore));
  });
}
