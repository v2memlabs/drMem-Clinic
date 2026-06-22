import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_session_list_refresh.dart';

void main() {
  test('patient rehab summary listens to referral and session refresh', () {
    final source = File('lib/features/patients/patient_detail_screen.dart')
        .readAsStringSync();

    expect(source.contains('PhysiotherapyReferralListRefresh'), isTrue);
    expect(source.contains('PhysiotherapySessionListRefresh'), isTrue);
    expect(
      source.contains('referralStale || sessionStale'),
      isTrue,
    );
  });

  test('session list refresh version increments', () {
    final before = PhysiotherapySessionListRefresh.version;
    PhysiotherapySessionListRefresh.markStale();
    expect(PhysiotherapySessionListRefresh.version, greaterThan(before));
    expect(
      PhysiotherapySessionListRefresh.isStale(before),
      isTrue,
    );
    expect(
      PhysiotherapyReferralListRefresh.isStale(
        PhysiotherapyReferralListRefresh.version,
      ),
      isFalse,
    );
  });
}
