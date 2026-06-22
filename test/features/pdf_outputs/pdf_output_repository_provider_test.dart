import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/repository_registry.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/async_pdf_output_repository_contract.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/mock_async_pdf_output_repository_adapter.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/pdf_output_repository_provider.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/supabase_async_pdf_output_repository_stub.dart';
import 'package:v2mem_clinic/features/pdf_outputs/data/supabase_pdf_output_repository.dart';
import 'package:v2mem_clinic/features/pdf_outputs/models/pdf_output.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

class _FakePdfRepo implements AsyncPdfOutputRepositoryContract {
  @override
  Future<List<PdfOutput>> getAll() async => const [];

  @override
  Future<PdfOutput?> getById(String id) async => null;

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async => const [];

  @override
  Future<List<PdfOutput>> search(String query) async => const [];
}

void main() {
  tearDown(() {
    PdfOutputRepositoryProvider.testOverride = null;
    PdfOutputRepositoryProvider.resetCache();
    AuthSession.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  group('PdfOutputRepositoryProvider', () {
    test('mock backend uses mock async adapter', () {
      AppBackendConfig.activeBackend = DataBackend.mock;
      PdfOutputRepositoryProvider.resetCache();

      expect(
        PdfOutputRepositoryProvider.asyncRepository,
        isA<MockAsyncPdfOutputRepositoryAdapter>(),
      );
      expect(PdfOutputRepositoryProvider.usesRemotePdfOutputs, isFalse);
    });

    test('supabase backend without session uses unavailable stub', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      PdfOutputRepositoryProvider.resetCache();

      expect(
        PdfOutputRepositoryProvider.asyncRepository,
        isA<SupabaseAsyncPdfOutputRepositoryStub>(),
      );
      expect(PdfOutputRepositoryProvider.usesRemotePdfOutputs, isFalse);
    });

    test('testOverride is returned from asyncRepository', () {
      final fake = _FakePdfRepo();
      PdfOutputRepositoryProvider.testOverride = fake;

      expect(PdfOutputRepositoryProvider.asyncRepository, same(fake));
      expect(
        RepositoryRegistry.pdfOutputsAsync,
        same(fake),
      );
    });

    test('doctor role alone does not enable remote without infra', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      PdfOutputRepositoryProvider.resetCache();

      expect(PdfOutputRepositoryProvider.usesRemotePdfOutputs, isFalse);
      expect(
        PdfOutputRepositoryProvider.asyncRepository,
        isA<SupabaseAsyncPdfOutputRepositoryStub>(),
      );
    });
  });
}
