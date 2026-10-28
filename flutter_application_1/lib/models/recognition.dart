class DetectionBox {
  const DetectionBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory DetectionBox.fromJson(Map<String, dynamic> json) => DetectionBox(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  final double x;
  final double y;
  final double width;
  final double height;
}

class Recognition {
  const Recognition({
    required this.brand,
    required this.model,
    required this.years,
    required this.confidence,
    this.carId,
    this.box,
  });

  factory Recognition.fromJson(Map<String, dynamic> json) {
    final box = json['box'] as Map<String, dynamic>?;
    return Recognition(
      carId: json['carId'] as String?,
      brand: json['brand'] as String,
      model: json['model'] as String,
      years: json['years'] as String,
      confidence: (json['confidence'] as num).round(),
      box: box == null ? null : DetectionBox.fromJson(box),
    );
  }

  final String brand;
  final String model;
  final String years;
  final int confidence;

  /// Identifiant de la voiture dans la liste de l'IA, utilisé pour l'entraîner.
  final String? carId;
  final DetectionBox? box;

  /// Vrai si chaque mot recherché apparaît dans la marque, le modèle ou les
  /// années, par exemple « bmw m4 » ou « clio 2019 ».
  bool matches(String query) {
    final text = '$brand $model $years'.toLowerCase();
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .every(text.contains);
  }
}

enum NoMatchReason { noCar, unknown }

class ScanResult {
  const ScanResult({
    this.recognition,
    this.reason = NoMatchReason.unknown,
    this.suggestions = const [],
    this.box,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final box = json['box'] as Map<String, dynamic>?;
    final suggestions = json['suggestions'] as List? ?? const [];
    return ScanResult(
      recognition:
          json['recognized'] as bool ? Recognition.fromJson(json) : null,
      reason: json['reason'] == 'no_car'
          ? NoMatchReason.noCar
          : NoMatchReason.unknown,
      suggestions: suggestions
          .map((item) => Recognition.fromJson(item as Map<String, dynamic>))
          .toList(),
      box: box == null ? null : DetectionBox.fromJson(box),
    );
  }

  /// Null quand l'IA n'est pas assez sûre : la voiture n'est pas reconnue.
  final Recognition? recognition;
  final NoMatchReason reason;
  final List<Recognition> suggestions;
  final DetectionBox? box;
}
