import 'scanned_car.dart';

enum LibrarySort {
  newest('Plus récentes'),
  oldest('Plus anciennes'),
  rarest('Plus rares'),
  priciest('Plus chères'),
  brand('Marque de A à Z');

  const LibrarySort(this.label);

  final String label;
}

/// Recherche, filtre de rareté et tri de la bibliothèque.
class LibraryFilter {
  const LibraryFilter({
    this.query = '',
    this.rarities = const {},
    this.sort = LibrarySort.newest,
  });

  final String query;

  /// Raretés gardées, toutes si l'ensemble est vide.
  final Set<Rarity> rarities;
  final LibrarySort sort;

  bool get isActive => query.trim().isNotEmpty || rarities.isNotEmpty;

  LibraryFilter copyWith({
    String? query,
    Set<Rarity>? rarities,
    LibrarySort? sort,
  }) =>
      LibraryFilter(
        query: query ?? this.query,
        rarities: rarities ?? this.rarities,
        sort: sort ?? this.sort,
      );

  LibraryFilter toggle(Rarity rarity) => copyWith(
        rarities: rarities.contains(rarity)
            ? ({...rarities}..remove(rarity))
            : {...rarities, rarity},
      );

  List<ScannedCar> apply(List<ScannedCar> cars) {
    final words = _simplify(query).split(' ').where((w) => w.isNotEmpty);
    final kept = cars.where((car) {
      if (rarities.isNotEmpty && !rarities.contains(car.rarity)) return false;
      final text = _simplify(
        '${car.recognition.brand} ${car.recognition.model} '
        '${car.location?.place.join(' ') ?? ''}',
      );
      return words.every(text.contains);
    }).toList();
    return kept..sort(_compare);
  }

  int _compare(ScannedCar a, ScannedCar b) {
    final byDate = b.scannedAt.compareTo(a.scannedAt);
    final order = switch (sort) {
      LibrarySort.newest => byDate,
      LibrarySort.oldest => -byDate,
      LibrarySort.rarest => b.rarity.index - a.rarity.index,
      // Les voitures sans prix connu vont à la fin
      LibrarySort.priciest => (b.price ?? -1).compareTo(a.price ?? -1),
      LibrarySort.brand =>
        _simplify('${a.recognition.brand} ${a.recognition.model}').compareTo(
            _simplify('${b.recognition.brand} ${b.recognition.model}')),
    };
    return order != 0 ? order : byDate;
  }
}

// Chaque lettre de _withAccent est remplacée par celle de même place
const _withAccent = 'àâäéèêëîïôöùûüç-';
const _plain = 'aaaeeeeiioouuuc ';

/// « Citroën DS-3 » devient « citroen ds 3 », pour chercher sans accents.
String _simplify(String text) => text.toLowerCase().split('').map((c) {
      final index = _withAccent.indexOf(c);
      return index < 0 ? c : _plain[index];
    }).join();
