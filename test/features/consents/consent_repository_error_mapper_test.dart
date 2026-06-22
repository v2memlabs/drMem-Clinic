import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/consents/data/consent_repository_failure.dart';

void main() {
  test('maps permission errors to forbidden', () {
    expect(
      ConsentRepositoryErrorMapper.toException(
        Exception('42501 permission denied'),
      ).reason,
      ConsentRepositoryFailure.forbidden,
    );
  });

  test('maps not found to notFound', () {
    expect(
      ConsentRepositoryErrorMapper.toException(
        Exception('PGRST116 not found'),
      ).reason,
      ConsentRepositoryFailure.notFound,
    );
  });

  test('maps unknown errors safely', () {
    expect(
      ConsentRepositoryErrorMapper.toException(Exception('unexpected')).reason,
      ConsentRepositoryFailure.unknown,
    );
  });
}
