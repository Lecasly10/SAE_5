import 'package:flutter_test/flutter_test.dart';
import 'package:spot_it/models/library_filter.dart';
import 'package:spot_it/models/scanned_car.dart';

ScannedCar car(
  String id,
  String brand,
  String model, {
  required String day,
  String rarity = 'commune',
  int? price,
  String? city,
}) =>
    ScannedCar.fromJson({
      'id': id,
      'brand': brand,
      'model': model,
      'years': '2010 – 2015',
      'confidence': 90,
      'createdAt': '2026-11-${day}T10:00:00Z',
      'rarity': rarity,
      'price': price,
      'location': city == null
          ? null
          : {
              'latitude': 0,
              'longitude': 0,
              'source': 'photo',
              'place': {'city': city},
            },
    });

void main() {
  final cars = [
    car('clio', 'Renault', 'Clio', day: '01', price: 15000),
    car('ds3', 'Citroën', 'DS 3', day: '03', rarity: 'rare', city: 'Lyon'),
    car('enzo', 'Ferrari', 'Enzo',
        day: '02', rarity: 'mythique', price: 650000),
  ];
  List<String> ids(LibraryFilter filter) =>
      filter.apply(cars).map((c) => c.id).toList();

  test('par défaut les voitures les plus récentes sont en premier', () {
    expect(ids(const LibraryFilter()), ['ds3', 'enzo', 'clio']);
    expect(const LibraryFilter().isActive, isFalse);
  });

  test('la recherche ignore les accents, les tirets et cherche le lieu', () {
    expect(ids(const LibraryFilter(query: 'citroen ds-3')), ['ds3']);
    expect(ids(const LibraryFilter(query: 'lyon')), ['ds3']);
    expect(ids(const LibraryFilter(query: 'porsche')), isEmpty);
  });

  test('le filtre de rareté garde seulement les raretés choisies', () {
    final filter =
        const LibraryFilter().toggle(Rarity.mythique).toggle(Rarity.rare);

    expect(ids(filter), ['ds3', 'enzo']);
    expect(ids(filter.toggle(Rarity.rare)), ['enzo']);
    expect(filter.isActive, isTrue);
  });

  test('chaque tri range les voitures dans le bon ordre', () {
    List<String> sorted(LibrarySort sort) => ids(LibraryFilter(sort: sort));

    expect(sorted(LibrarySort.oldest), ['clio', 'enzo', 'ds3']);
    expect(sorted(LibrarySort.rarest), ['enzo', 'ds3', 'clio']);
    // Sans prix connu, la DS 3 va à la fin
    expect(sorted(LibrarySort.priciest), ['enzo', 'clio', 'ds3']);
    expect(sorted(LibrarySort.brand), ['ds3', 'enzo', 'clio']);
  });
}
