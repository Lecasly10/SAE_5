import 'package:flutter_test/flutter_test.dart';
import 'package:spot_it/models/collection_stats.dart';
import 'package:spot_it/models/scanned_car.dart';

void main() {
  const car = {
    'id': 'abc',
    'brand': 'Ferrari',
    'model': 'F12',
    'years': '2012 – 2017',
    'confidence': 91,
    'createdAt': '2026-11-02T10:00:00Z',
  };

  test('une voiture garde sa rareté et le lieu de la photo', () {
    final scanned = ScannedCar.fromJson({
      ...car,
      'rarity': 'legendaire',
      'price': 279600,
      'produced': 1500,
      'location': {
        'latitude': 48.8584,
        'longitude': 2.2945,
        'source': 'photo',
        'place': {'name': 'Port Hercule', 'city': 'Monaco', 'country': 'Monaco'},
      },
    });

    expect(scanned.rarity, Rarity.legendaire);
    expect(scanned.rarity.label, 'Légendaire');
    expect(scanned.price, 279600);
    expect(formatEuros(scanned.price!), '279 600 €');
    expect(formatEuros(950), '950 €');
    expect(scanned.location!.fromPhoto, isTrue);
    expect(scanned.location!.coordinates, '48.8584, 2.2945');
    // Ville et pays du même nom : écrit une seule fois
    expect(scanned.location!.label, 'Port Hercule, Monaco');
    expect(scanned.produced, 1500);
    expect(Rarity.fromJson('mythique').label, 'Mythique');
    expect(scanned.location!.toJson(), {'latitude': 48.8584, 'longitude': 2.2945});
  });

  test("une ancienne voiture sans rareté ni lieu reste lisible", () {
    final scanned = ScannedCar.fromJson({...car, 'location': null});

    expect(scanned.rarity, Rarity.commune);
    expect(scanned.location, isNull);
    expect(scanned.price, isNull);
    expect(scanned.produced, isNull);
  });

  test('les statistiques donnent la part de la collection complétée', () {
    final stats = CollectionStats.fromJson({
      'total': 3,
      'models': 2,
      'brands': 2,
      'catalogSize': 1170,
      'rarities': {'commune': 2, 'rare': 0, 'epique': 0, 'legendaire': 1},
      'rarest': {'brand': 'Ferrari', 'model': 'F12', 'rarity': 'legendaire'},
      'topBrands': [
        {'brand': 'Peugeot', 'count': 2},
        {'brand': 'Ferrari', 'count': 1},
      ],
      'located': 1,
      'value': 289700,
      'priced': 2,
      'priciest': {'brand': 'Ferrari', 'model': 'F12', 'price': 279600},
      'firstSpot': '2026-11-01T09:00:00Z',
      'lastSpot': '2026-11-03T09:00:00Z',
    });

    expect(stats.completion, closeTo(2 / 1170, 1e-9));
    expect(stats.rarities[Rarity.legendaire], 1);
    expect(stats.rarest, ('Ferrari F12', Rarity.legendaire));
    expect(stats.topBrands.first, ('Peugeot', 2));
    expect(stats.value, 289700);
    expect(stats.priciest, ('Ferrari F12', 279600));
  });

  test("sans l'IA, les statistiques n'ont pas de pourcentage", () {
    final stats = CollectionStats.fromJson({
      'total': 0,
      'models': 0,
      'brands': 0,
      'catalogSize': null,
      'rarities': <String, dynamic>{},
      'rarest': null,
      'topBrands': <dynamic>[],
      'located': 0,
      'firstSpot': null,
      'lastSpot': null,
    });

    expect(stats.completion, isNull);
    expect(stats.rarities[Rarity.rare], 0);
  });

  test('sans nom de lieu, la position reste lisible', () {
    final location = CarLocation.fromJson(
      {'latitude': 43.7384, 'longitude': 7.4246, 'source': 'device'},
    );

    expect(location.label, '43.7384, 7.4246');
    expect(location.fromPhoto, isFalse);
  });
}
