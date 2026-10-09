import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'car_service.dart';
import 'framed_image.dart';
import 'recognition.dart';
import 'spot_it_theme.dart';

class CarImage extends StatefulWidget {
  const CarImage({
    required this.carId,
    this.fit = BoxFit.cover,
    this.zoomable = false,
    this.box,
    super.key,
  });

  final String carId;
  final BoxFit fit;
  final bool zoomable;
  final DetectionBox? box;

  @override
  State<CarImage> createState() => _CarImageState();
}

class _CarImageState extends State<CarImage> {
  late final Future<Uint8List> _bytes = CarService.image(widget.carId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return _ImagePlaceholder(failed: snapshot.hasError);

        final image = FramedImage(
          bytes: bytes,
          box: widget.box,
          fit: widget.fit,
        );
        return widget.zoomable
            ? InteractiveViewer(minScale: 1, maxScale: 5, child: image)
            : image;
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SpotItColors.selectedSurface,
      child: Center(
        child: failed
            ? const Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: SpotItColors.disabledText,
              )
            : const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SpotItColors.accent,
                ),
              ),
      ),
    );
  }
}
