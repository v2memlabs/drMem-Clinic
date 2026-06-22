import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/payments/data/payment_permissions.dart';
import 'package:v2mem_clinic/features/payments/models/payment_record.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

PaymentRecord _record({String? createdByUserId}) {
  return PaymentRecord(
    id: 'pay-1',
    patientId: 'p1',
    patientName: 'Hasta',
    createdAt: DateTime(2026, 1, 1),
    serviceType: ServiceType.muayene,
    totalAmount: 100,
    paidAmount: 0,
    paymentMethod: PaymentMethod.nakit,
    paymentStatus: PaymentStatus.bekliyor,
    invoiceStatus: InvoiceStatus.belirtilmedi,
    transactionDate: DateTime(2026, 1, 1),
    recordedBy: 'Test',
    createdByUserId: createdByUserId,
  );
}

void main() {
  tearDown(() => AuthSession.clear());

  test('physiotherapist can edit own payment only', () {
    AuthSession.setUser(
      AppUser(
        id: 'physio-1',
        username: 'physio',
        displayName: 'Fizyoterapist',
        role: AppRoles.physiotherapist,
      ),
    );

    expect(
      PaymentPermissions.canEditPayment(_record(createdByUserId: 'physio-1')),
      isTrue,
    );
    expect(
      PaymentPermissions.canEditPayment(_record(createdByUserId: 'other')),
      isFalse,
    );
  });

  test('assistant can edit any payment', () {
    AuthSession.setUser(
      AppUser(
        id: 'asst-1',
        username: 'asst',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    expect(
      PaymentPermissions.canEditPayment(_record(createdByUserId: 'other')),
      isTrue,
    );
  });
}
