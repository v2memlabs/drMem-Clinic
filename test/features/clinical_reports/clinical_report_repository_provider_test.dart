import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_repository_failure.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/clinical_report_repository_provider.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/mock_async_clinical_report_repository_adapter.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/supabase_async_clinical_report_repository_stub.dart';
import 'package:v2mem_clinic/features/clinical_reports/data/supabase_clinical_report_repository.dart';

void main() {
  tearDown(() {
    ClinicalReportRepositoryProvider.clearTestOverrides();
    ClinicalReportRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('clinical reports capability flag is true', () {
    expect(
      OperationalRecordsRemoteCapabilities.clinicalReportsTableReady,
      isTrue,
    );
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ClinicalReportRepositoryProvider.resetCache();

    expect(
      ClinicalReportRepositoryProvider.asyncRepository,
      isA<MockAsyncClinicalReportRepositoryAdapter>(),
    );
    expect(ClinicalReportRepositoryProvider.usesRemoteClinicalReports, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ClinicalReportRepositoryProvider.resetCache();

    expect(
      ClinicalReportRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncClinicalReportRepositoryStub>(),
    );
    expect(ClinicalReportRepositoryProvider.usesRemoteClinicalReports, isFalse);
  });

  test('supabase without session does not resolve Supabase repository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ClinicalReportRepositoryProvider.resetCache();

    expect(
      ClinicalReportRepositoryProvider.asyncRepository,
      isNot(isA<SupabaseClinicalReportRepository>()),
    );
  });

  test('unavailable stub throws notConfigured', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    ClinicalReportRepositoryProvider.resetCache();

    await expectLater(
      ClinicalReportRepositoryProvider.asyncRepository.getAll(),
      throwsA(
        isA<ClinicalReportRepositoryException>().having(
          (e) => e.reason,
          'reason',
          ClinicalReportRepositoryFailure.notConfigured,
        ),
      ),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    ClinicalReportRepositoryProvider.resetCache();

    const stub = SupabaseAsyncClinicalReportRepositoryStub();
    ClinicalReportRepositoryProvider.testOverride = stub;

    expect(ClinicalReportRepositoryProvider.asyncRepository, same(stub));
  });
}
