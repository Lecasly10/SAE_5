import 'recognition.dart';

/// Rareté d'une voiture, calculée par le serveur.
enum Rarity {
  commune('Commune'),
  rare('Rare'),
  epique('Épique'),
  legendaire('Légendaire'),
  mythique('Mythique');

  const Rarity(this.label);

  final String label;

  static Rarity fromJson(Object? value) =>
      Rarity.values.firstWhere((r) => r.name == value, orElse: () => commune);
}

/// À quelle fréquence on croise cette voiture là où la photo a été prise.
enum OnRoad {
  courante('Courante'),
  peuCourante('Peu courante'),
  tresRare('Très rare');

  const OnRoad(this.label);

  final String label;

  static OnRoad? fromJson(Object? value) => switch (value) {
        'courante' => courante,
        'peu_courante' => peuCourante,
        'tres_rare' => tresRare,
        _ => null,
      };
}

/// Endroit où la photo a été prise.
class CarLocation {
  const CarLocation({
    required this.latitude,
    required this.longitude,
    required this.fromPhoto,
    this.place = const [],
  });

  factory CarLocation.fromJson(Map<String, dynamic> json) {
    final place = json['place'] as Map<String, dynamic>?;
    return CarLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fromPhoto: json['source'] == 'photo',
      place: [
        for (final key in ['name', 'city', 'country'])
          if (place?[key] case final String part when part.isNotEmpty) part,
      ],
    );
  }

  final double latitude;
  final double longitude;

  /// Vrai si la position vient de la photo, faux si c'est celle du téléphone.
  final bool fromPhoto;

  /// Lieu le plus proche, sa ville et son pays (vide si inconnu).
  final List<String> place;

  Map<String, double> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  String get coordinates =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  /// « Port Hercule, Monaco », ou les coordonnées si le lieu est inconnu.
  String get label =>
      place.isEmpty ? coordinates : place.toSet().join(', ');
}

class ScannedCar {
  const ScannedCar({
    required this.id,
    required this.recognition,
    required this.scannedAt,
    this.rarity = Rarity.commune,
    this.location,
    this.price,
    this.produced,
    this.onRoad,
  });

  factory ScannedCar.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return ScannedCar(
      id: json['id'] as String,
      recognition: Recognition.fromJson(json),
      scannedAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      rarity: Rarity.fromJson(json['rarity']),
      location: location == null ? null : CarLocation.fromJson(location),
      price: (json['price'] as num?)?.round(),
      produced: (json['produced'] as num?)?.round(),
      onRoad: OnRoad.fromJson(json['onRoad']),
    );
  }

  final String id;
  final Recognition recognition;
  final DateTime scannedAt;
  final Rarity rarity;
  final CarLocation? location;

  /// Prix neuf en euros, null si on ne le connaît pas.
  final int? price;

  /// Exemplaires fabriqués, seulement pour les séries limitées.
  final int? produced;
  final OnRoad? onRoad;

  String get scannedDate => formatDate(scannedAt);
}

/// « 279 600 » : les milliers séparés par une espace fine.
String formatNumber(int value) {
  final digits = value.toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.insert(0, digits.substring(end < 3 ? 0 : end - 3, end));
  }
  return groups.join(' ');
}

/// « 279 600 € »
String formatEuros(int value) => '${formatNumber(value)} €';

String formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}
