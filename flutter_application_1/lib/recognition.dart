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
    this.box,
  });

  factory Recognition.fromJson(Map<String, dynamic> json) {
    final box = json['box'] as Map<String, dynamic>?;
    return Recognition(
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
  final DetectionBox? box;
}
