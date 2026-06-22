import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/payments/data/payment_repository.dart';
import 'package:v2mem_clinic/features/payments/models/payment_record.dart';
import 'package:v2mem_clinic/features/payments/payment_list_screen.dart';
import 'package:v2mem_clinic/features/payments/widgets/payment_clinical_list_row.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/shared/widgets/clinical_separated_list_body.dart';
import 'package:v2mem_clinic/shared/widgets/status_chip.dart';

void main() {
  tearDown(AuthSession.clear);

  testWidgets('payment list uses clinical rows and legend', (tester) async {
    AuthSession.setUser(
      AppUser(
        id: 'a1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PaymentListScreen(),
        ),
        GoRoute(
          path: '/payments/:id',
          builder: (context, state) =>
              Scaffold(body: Text('Payment ${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentClinicalListRow), findsWidgets);
    expect(find.byType(ClinicalSeparatedListBody), findsWidgets);
    expect(find.text('Toplam Tahakkuk'), findsOneWidget);
    expect(find.text('Tahsil Edilen'), findsOneWidget);
    expect(find.text('Kalan Bakiye'), findsOneWidget);
    expect(find.text('Bekleyen Kayıt'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(find.text('Durum renkleri'), findsOneWidget);
    expect(find.text('Yeni Kayıt'), findsOneWidget);

    await tester.tap(find.byType(PaymentClinicalListRow).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Payment'), findsOneWidget);
  });

  testWidgets('paid payment row hides semantic status chip', (tester) async {
    final paid = PaymentRepository.instance.getAll().firstWhere(
          (p) => p.paymentStatus == PaymentStatus.odendi,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentClinicalListRow(
            record: paid,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(StatusChip), findsNothing);
  });
}
