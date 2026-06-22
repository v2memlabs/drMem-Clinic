import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/settings/data/staff_leave_record_repository.dart';
import 'package:v2mem_clinic/features/settings/data/staff_leave_record_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/staff_leave_record.dart';
import 'package:v2mem_clinic/features/settings/staff_leave_settings_screen.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_notice.dart';

class _InMemoryStaffLeaveRepo implements StaffLeaveRecordRepository {
  final List<StaffLeaveRecord> records = [];
  int createCount = 0;
  int cancelCount = 0;

  @override
  Future<StaffLeaveRecord> create(StaffLeaveDraft draft) async {
    createCount++;
    final now = DateTime.now();
    final record = StaffLeaveRecord(
      id: 'r$createCount',
      staffDisplayName: draft.staffDisplayName.trim(),
      roleLabel: draft.roleLabel,
      leaveType: draft.leaveType,
      startsAt: draft.startsAt,
      endsAt: draft.endsAt,
      note: draft.note,
      status: StaffLeaveStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    records.insert(0, record);
    return record;
  }

  @override
  Future<void> cancel(String id) async {
    cancelCount++;
    final i = records.indexWhere((r) => r.id == id);
    if (i >= 0) {
      records[i] = records[i].copyWith(
        status: StaffLeaveStatus.cancelled,
        cancelledAt: DateTime.now(),
      );
    }
  }

  @override
  Future<StaffLeaveRecord?> getById(String id) async {
    for (final r in records) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<List<StaffLeaveRecord>> list() async => List.from(records);

  @override
  Future<List<StaffLeaveRecord>> listActiveForCalendarDay(
    DateTime calendarDay,
  ) async {
    final dayStart = DateTime(
      calendarDay.year,
      calendarDay.month,
      calendarDay.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    return records
        .where((r) {
          if (!r.isActive) return false;
          final start = r.startsAt.toLocal();
          final end = r.endsAt.toLocal();
          return end.isAfter(dayStart) && start.isBefore(dayEnd);
        })
        .toList();
  }

  @override
  Future<StaffLeaveRecord> update(StaffLeaveRecord record) async {
    final i = records.indexWhere((r) => r.id == record.id);
    if (i >= 0) records[i] = record;
    return record;
  }
}

void main() {
  tearDown(() {
    AuthSession.clear();
    StaffLeaveRecordRepositoryProvider.testOverride = null;
  });

  Future<void> pumpScreen(WidgetTester tester, {required String role}) async {
    AuthSession.setUser(
      AppUser(
        id: 'u1',
        username: 'test',
        displayName: 'Test',
        role: role,
      ),
    );

    final router = GoRouter(
      initialLocation: '/settings/clinic-workflow/staff-leaves',
      routes: [
        GoRoute(
          path: '/settings/clinic-workflow',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/settings/clinic-workflow/staff-leaves',
          builder: (context, state) => const StaffLeaveSettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  group('StaffLeaveSettingsScreen', () {
    testWidgets('shows availability disclaimer', (tester) async {
      StaffLeaveRecordRepositoryProvider.testOverride =
          _InMemoryStaffLeaveRepo();

      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.doctor);

      expect(find.textContaining('v1'), findsNothing);
      expect(
        find.textContaining('çakışan randevu saatlerini kapatır'),
        findsOneWidget,
      );
      expect(find.byType(ClinicalNotice), findsWidgets);
      expect(find.textContaining('tenant_id'), findsNothing);
      expect(find.textContaining('profile_id'), findsNothing);
    });

    testWidgets('doctor can add leave', (tester) async {
      final repo = _InMemoryStaffLeaveRepo();
      StaffLeaveRecordRepositoryProvider.testOverride = repo;

      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.doctor);

      expect(find.text('İzin ekle'), findsOneWidget);
      await tester.tap(find.text('İzin ekle'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Personel adı *'),
        'Dr. Ayşe',
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(repo.createCount, 1);
      expect(find.text('Dr. Ayşe'), findsWidgets);
    });

    testWidgets('assistant read-only without add button', (tester) async {
      final repo = _InMemoryStaffLeaveRepo()
        ..records.add(
          StaffLeaveRecord(
            id: 'r1',
            staffDisplayName: 'Dr. Mehmet',
            leaveType: StaffLeaveType.annual,
            startsAt: DateTime(2026, 7, 1, 9),
            endsAt: DateTime(2026, 7, 5, 18),
            status: StaffLeaveStatus.active,
            createdAt: DateTime(2026, 6, 1),
            updatedAt: DateTime(2026, 6, 1),
          ),
        );
      StaffLeaveRecordRepositoryProvider.testOverride = repo;

      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.assistant);

      expect(find.text('İzin ekle'), findsNothing);
      expect(find.text('Düzenle'), findsNothing);
      expect(find.textContaining('görüntüleme modundasınız'), findsOneWidget);
      expect(find.text('Dr. Mehmet'), findsOneWidget);
    });

    testWidgets('empty state when no records', (tester) async {
      StaffLeaveRecordRepositoryProvider.testOverride =
          _InMemoryStaffLeaveRepo();

      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(tester, role: AppRoles.doctor);

      expect(
        find.textContaining('Henüz personel izin kaydı'),
        findsOneWidget,
      );
    });
  });
}
