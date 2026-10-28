import 'recognition.dart';

class ScannedCar {
  const ScannedCar({
    required this.id,
    required this.recognition,
    required this.scannedAt,
  });

  factory ScannedCar.fromJson(Map<String, dynamic> json) => ScannedCar(
        id: json['id'] as String,
        recognition: Recognition.fromJson(json),
        scannedAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  final String id;
  final Recognition recognition;
  final DateTime scannedAt;

  String get scannedDate {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(scannedAt.day)}/${twoDigits(scannedAt.month)}/${scannedAt.year}';
  }
}
