import 'package:flutter_test/flutter_test.dart';
import 'package:spot_it/models/recognition.dart';

void main() {
  const box = {'x': 0.1, 'y': 0.2, 'width': 0.5, 'height': 0.4};

  test('une voiture reconnue donne une Recognition', () {
    final result = ScanResult.fromJson({
      'recognized': true,
      'confidence': 91,
      'brand': 'Renault',
      'model': 'Clio',
      'years': '2012 – 2019',
      'box': box,
      'suggestions': [],
    });

    expect(result.recognition, isNotNull);
    expect(result.recognition!.brand, 'Renault');
    expect(result.recognition!.confidence, 91);
    expect(result.box!.width, 0.5);
  });

  test('une voiture non reconnue garde les suggestions', () {
    final result = ScanResult.fromJson({
      'recognized': false,
      'reason': 'unknown',
      'confidence': 38,
      'box': box,
      'suggestions': [
        {
          'brand': 'Peugeot',
          'model': '208',
          'years': '2019 – aujourd’hui',
          'confidence': 38
        },
        {
          'brand': 'Renault',
          'model': 'Clio',
          'years': '2012 – 2019',
          'confidence': 25
        },
      ],
    });

    expect(result.recognition, isNull);
    expect(result.reason, NoMatchReason.unknown);
    expect(result.suggestions.map((car) => car.model), ['208', 'Clio']);
  });

  test('sans voiture détectée la raison est noCar et il n’y a pas de cadre',
      () {
    final result = ScanResult.fromJson({
      'recognized': false,
      'reason': 'no_car',
      'confidence': 9,
      'box': null,
      'suggestions': [],
    });

    expect(result.reason, NoMatchReason.noCar);
    expect(result.box, isNull);
  });

  test("l'identifiant de chaque voiture est gardé pour entraîner l'IA", () {
    final result = ScanResult.fromJson({
      'recognized': true,
      'confidence': 72,
      'carId': 'peugeot_208_2019_present',
      'brand': 'Peugeot',
      'model': '208',
      'years': '2019 – aujourd’hui',
      'box': null,
      'suggestions': [
        {
          'carId': 'peugeot_2008_2019_present',
          'brand': 'Peugeot',
          'model': '2008',
          'years': '2019 – aujourd’hui',
          'confidence': 9
        },
      ],
    });

    expect(result.recognition!.carId, 'peugeot_208_2019_present');
    expect(result.suggestions.single.carId, 'peugeot_2008_2019_present');
  });

  test('la recherche de voiture accepte plusieurs mots dans le désordre', () {
    const m4 = Recognition(
      brand: 'BMW',
      model: 'M4 G82',
      years: '2020 – aujourd’hui',
      confidence: 0,
    );

    expect(m4.matches(''), isTrue);
    expect(m4.matches('bmw m4'), isTrue);
    expect(m4.matches('  G82   2020 bmw '), isTrue);
    expect(m4.matches('bmw m3'), isFalse);
  });
}
