import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_error_mapper.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_failure.dart';

void main() {
  test('maps RPC insufficient stock to Turkish validation', () {
    expect(
      InventoryRepositoryErrorMapper.toValidationMessage(
        Exception('INV_MOV_INSUFFICIENT_STOCK'),
      ),
      'Çıkış miktarı mevcut stoktan fazla olamaz.',
    );
  });

  test('maps inactive item RPC code', () {
    expect(
      InventoryRepositoryErrorMapper.toValidationMessage(
        Exception('INV_MOV_ITEM_INACTIVE'),
      ),
      'Pasif stok kartına hareket eklenemez.',
    );
  });

  test('maps permission errors to forbidden', () {
    expect(
      InventoryRepositoryErrorMapper.toException(
        Exception('INV_MOV_FORBIDDEN 42501'),
      ).reason,
      InventoryRepositoryFailure.forbidden,
    );
  });

  test('maps unknown errors safely', () {
    expect(
      InventoryRepositoryErrorMapper.toException(Exception('unexpected')).reason,
      InventoryRepositoryFailure.unknown,
    );
  });
}
