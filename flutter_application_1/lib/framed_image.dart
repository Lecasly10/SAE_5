import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'recognition.dart';
import 'spot_it_theme.dart';

class FramedImage extends StatefulWidget {
  const FramedImage({
    required this.bytes,
    this.box,
    this.fit = BoxFit.contain,
    this.revealDelay = const Duration(milliseconds: 450),
    super.key,
  });

  final Uint8List bytes;
  final DetectionBox? box;
  final BoxFit fit;
  final Duration revealDelay;

  @override
  State<FramedImage> createState() => _FramedImageState();
}

class _FramedImageState extends State<FramedImage> {
  static const Duration _drawDuration = Duration(milliseconds: 700);

  Future<Size>? _imageSize;

  @override
  void didUpdateWidget(FramedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) _imageSize = null;
  }

  static Future<Size> _decodeSize(Uint8List bytes) async {
    final image = await decodeImageFromList(bytes);
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  Widget _frame(DetectionBox box) {
    _imageSize ??= _decodeSize(widget.bytes);
    final total = widget.revealDelay + _drawDuration;

    return FutureBuilder<Size>(
      future: _imageSize,
      builder: (context, snapshot) {
        final imageSize = snapshot.data;
        if (imageSize == null) return const SizedBox.shrink();

        return TweenAnimationBuilder<double>(
          key: ValueKey(identityHashCode(widget.bytes)),
          tween: Tween(begin: 0, end: 1),
          duration: total,
          curve: Interval(
            widget.revealDelay.inMilliseconds / total.inMilliseconds,
            1,
            curve: Curves.easeOutBack,
          ),
          builder: (context, progress, _) => CustomPaint(
            painter: _FramePainter(
              box: box,
              imageSize: imageSize,
              fit: widget.fit,
              progress: progress,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(widget.bytes, fit: widget.fit, gaplessPlayback: true),
        if (box != null) _frame(box),
      ],
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.box,
    required this.imageSize,
    required this.fit,
    required this.progress,
  });

  final DetectionBox box;
  final Size imageSize;
  final BoxFit fit;
  final double progress;

  Rect _boxOnCanvas(Size canvas) {
    final fitted = applyBoxFit(fit, imageSize, canvas);
    final target = Alignment.center.inscribe(fitted.destination, Offset.zero & canvas);
    final source = Alignment.center.inscribe(fitted.source, Offset.zero & imageSize);
    final scaleX = target.width / source.width;
    final scaleY = target.height / source.height;

    return Rect.fromLTWH(
      target.left + (box.x * imageSize.width - source.left) * scaleX,
      target.top + (box.y * imageSize.height - source.top) * scaleY,
      box.width * imageSize.width * scaleX,
      box.height * imageSize.height * scaleY,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _boxOnCanvas(size);
    final opacity = progress.clamp(0.0, 1.0);
    final animated = rect.inflate((1 - progress) * 0.12 * math.min(rect.width, rect.height));
    final rounded = RRect.fromRectAndRadius(animated, const Radius.circular(10));

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    canvas.drawRRect(
      rounded,
      Paint()
        ..color = SpotItColors.detection.withValues(alpha: 0.4 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = SpotItColors.detection.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final length = math.min(26.0, math.min(animated.width, animated.height) / 3);
    final corners = Path()
      ..moveTo(animated.left, animated.top + length)
      ..lineTo(animated.left, animated.top)
      ..lineTo(animated.left + length, animated.top)
      ..moveTo(animated.right - length, animated.top)
      ..lineTo(animated.right, animated.top)
      ..lineTo(animated.right, animated.top + length)
      ..moveTo(animated.left, animated.bottom - length)
      ..lineTo(animated.left, animated.bottom)
      ..lineTo(animated.left + length, animated.bottom)
      ..moveTo(animated.right - length, animated.bottom)
      ..lineTo(animated.right, animated.bottom)
      ..lineTo(animated.right, animated.bottom - length);
    canvas.drawPath(
      corners,
      Paint()
        ..color = SpotItColors.detection.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.box != box ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.fit != fit;
}
