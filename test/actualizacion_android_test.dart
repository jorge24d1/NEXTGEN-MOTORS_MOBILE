import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/actualizacion_android.dart';

void main() {
  test('Solo avisa para una ficha completa con compilación posterior', () {
    final ficha = {'version': '1.0.1', 'codigo': 2, 'novedades': 'Mejoras en citas'};
    expect(ActualizacionAndroid.hayActualizacion(1, ficha), isTrue);
    expect(ActualizacionAndroid.hayActualizacion(2, ficha), isFalse);
    expect(ActualizacionAndroid.hayActualizacion(3, ficha), isFalse);
    expect(ActualizacionAndroid.hayActualizacion(1, {'codigo': 3}), isFalse);
  });
}
