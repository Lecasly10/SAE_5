import 'scanned_car.dart';

/// Statistiques de la collection de l'utilisateur.
class CollectionStats {
  const CollectionStats({
    required this.total,
    required this.models,
    required this.brands,
    required this.catalogSize,
    required this.rarities,
    required this.topBrands,
    required this.located,
    required this.value,
    required this.priced,
    this.rarest,
    this.priciest,
    this.firstSpot,
  });

  factory CollectionStats.fromJson(Map<String, dynamic> json) {
    final rarities = json['rarities'] as Map<String, dynamic>;
    final rarest = json['rarest'] as Map<String, dynamic>?;
    final priciest = json['priciest'] as Map<String, dynamic>?;
    final firstSpot = json['firstSpot'] as String?;
    return CollectionStats(
      total: json['total'] as int,
      models: json['models'] as int,
      brands: json['brands'] as int,
      catalogSize: json['catalogSize'] as int?,
      rarities: {
        for (final rarity in Rarity.values)
          rarity: (rarities[rarity.name] as num? ?? 0).toInt(),
      },
      topBrands: [
        for (final item in json['topBrands'] as List)
          (
            (item as Map<String, dynamic>)['brand'] as String,
            (item['count'] as num).toInt(),
          ),
      ],
      located: json['located'] as int,
      value: (json['value'] as num? ?? 0).round(),
      priced: json['priced'] as int? ?? 0,
      priciest: priciest == null
          ? null
          : (
              '${priciest['brand']} ${priciest['model']}'.trim(),
              (priciest['price'] as num).round(),
            ),
      rarest: rarest == null
          ? null
          : (
              '${rarest['brand']} ${rarest['model']}'.trim(),
              Rarity.fromJson(rarest['rarity']),
            ),
      firstSpot:
          firstSpot == null ? null : DateTime.parse(firstSpot).toLocal(),
    );
  }

  final int total;
  final int models;
  final int brands;

  /// Nombre de voitures que l'IA connaît, null si l'IA ne répond pas.
  final int? catalogSize;
  final Map<Rarity, int> rarities;
  final List<(String, int)> topBrands;
  final int located;
  final (String, Rarity)? rarest;

  /// Prix neuf additionné des [priced] voitures dont on connaît le prix.
  final int value;
  final int priced;
  final (String, int)? priciest;
  final DateTime? firstSpot;

  /// Part des voitures connues de l'IA déjà repérées, de 0 à 1.
  double? get completion {
    final size = catalogSize;
    return size == null || size == 0 ? null : models / size;
  }
}
