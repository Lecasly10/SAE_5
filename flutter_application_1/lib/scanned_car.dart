class ScannedCar {
  const ScannedCar({
    required this.id,
    required this.recognizedName,
    required this.caption,
    required this.scannedAt,
  });

  factory ScannedCar.fromJson(Map<String, dynamic> json) => ScannedCar(
        id: json['id'] as String,
        recognizedName: json['recognizedName'] as String,
        caption: (json['caption'] as String?) ?? '',
        scannedAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final String id;
  final String recognizedName;
  final String caption;
  final DateTime scannedAt;
}
