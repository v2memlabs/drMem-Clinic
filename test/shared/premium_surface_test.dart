import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/shared/widgets/premium_surface.dart';

void main() {
  group('PremiumSurface', () {
    test('card default has no gradient and no shadow', () {
      final decoration = PremiumSurface.card();
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
    });

    test('panel has border and no shadow', () {
      final decoration = PremiumSurface.panel();
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNull);
      expect(decoration.gradient, isNull);
    });

    test('contentHeaderBand has bottom border only', () {
      final decoration = PremiumSurface.contentHeaderBand();
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
      final border = decoration.border as Border?;
      expect(border?.bottom.color, isNotNull);
    });

    test('accentTopEdge opt-in still adds gradient', () {
      final decoration = PremiumSurface.card(accentTopEdge: true);
      expect(decoration.gradient, isNotNull);
    });
  });
}
