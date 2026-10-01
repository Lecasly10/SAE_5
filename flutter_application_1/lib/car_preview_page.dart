import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'car_caption.dart';
import 'car_service.dart';
import 'scanned_car.dart';
import 'spot_it_theme.dart';
import 'toast.dart';

class CarPreviewPage extends StatefulWidget {
  const CarPreviewPage({required this.car, super.key});

  final ScannedCar car;

  static String heroTag(String carId) => 'car-image-$carId';

  @override
  State<CarPreviewPage> createState() => _CarPreviewPageState();
}

class _CarPreviewPageState extends State<CarPreviewPage> {
  late final Future<Uint8List> _bytes = CarService.image(widget.car.id);
  bool _deleting = false;

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SpotItColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 354),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: SpotItColors.border),
        ),
        title: Text(
          'Supprimer cette photo ?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Elle sera retirée de votre bibliothèque. Cette action est définitive.',
          style: GoogleFonts.inter(color: SpotItColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SpotItColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _deleting = true);
    try {
      await CarService.delete(widget.car.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showSpotItToast(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpotItColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: Column(
              children: [
                _PreviewHeader(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _ZoomableImage(bytes: _bytes, carId: widget.car.id)),
                        const SizedBox(height: 16),
                        CarCaption(text: widget.car.caption),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _deleting ? null : _delete,
                            icon: _deleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SpotItColors.danger,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline),
                            label: Text(
                              'Supprimer de la bibliothèque',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SpotItColors.danger,
                              side: const BorderSide(color: SpotItColors.danger),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 91,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Material(
              color: SpotItColors.surface,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(20),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Aperçu',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.bytes, required this.carId});

  final Future<Uint8List> bytes;
  final String carId;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: CarPreviewPage.heroTag(carId),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: SpotItColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SpotItColors.border),
        ),
        child: FutureBuilder<Uint8List>(
          future: bytes,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            }
            return Center(
              child: snapshot.hasError
                  ? const Icon(
                      Icons.broken_image_outlined,
                      size: 44,
                      color: SpotItColors.disabledText,
                    )
                  : const CircularProgressIndicator(
                      color: SpotItColors.accent,
                    ),
            );
          },
        ),
      ),
    );
  }
}
