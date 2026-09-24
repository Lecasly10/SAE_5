class ScannedCar {
  const ScannedCar({
    required this.imagePath,
    required this.recognizedName,
    required this.scannedAt,
  });

  final String imagePath;
  final String recognizedName;
  final DateTime scannedAt;
}
