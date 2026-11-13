import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scanned_car.dart';
import '../services/api.dart';
import '../services/car_service.dart';
import '../services/share_service.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/car_image.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/spot_it_widgets.dart';
import '../widgets/toast.dart';
import 'car_showcase_dialog.dart';

Future<bool> showCarCardDialog(BuildContext context, ScannedCar car) async {
  final deleted = await showShowcaseDialog<bool>(
    context,
    (_) => _CarCardDialog(car: car),
  );
  return deleted == true;
}

class _CarCardDialog extends StatefulWidget {
  const _CarCardDialog({required this.car});

  final ScannedCar car;

  @override
  State<_CarCardDialog> createState() => _CarCardDialogState();
}

class _CarCardDialogState extends State<_CarCardDialog> {
  bool _deleting = false;
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final shared = await ShareService.shareCar(
        widget.car,
        await CarService.image(widget.car.id),
      );
      // Navigateur sans partage : le texte est copié pour le coller ailleurs
      if (!shared) {
        await Clipboard.setData(
          ClipboardData(text: ShareService.textFor(widget.car)),
        );
        if (!mounted) return;
        showSpotItToast(context, 'Partage indisponible ici : texte copié');
      }
    } catch (_) {
      if (!mounted) return;
      showSpotItToast(context, 'Partage impossible sur cet appareil',
          isError: true);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cette photo ?',
      message:
          'Elle sera retirée de votre bibliothèque. Cette action est définitive.',
    );
    if (!confirmed || !mounted) return;

    HapticFeedback.mediumImpact();
    setState(() => _deleting = true);
    try {
      await CarService.delete(widget.car.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showSpotItToast(context, errorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return CarShowcaseDialog(
      label: 'FICHE VOITURE',
      recognition: car.recognition,
      discoveredOn: car.scannedDate,
      // Confiance nulle : voiture choisie dans la liste par l'utilisateur
      showConfidence: car.recognition.confidence > 0,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: RarityBadge(rarity: car.rarity)),
          if (car.price != null || car.onRoad != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (car.price != null)
                  _Detail(
                    icon: Icons.sell_outlined,
                    text: 'Neuve : ${formatEuros(car.price!)}',
                  ),
                if (car.price != null && car.onRoad != null)
                  const SizedBox(width: 14),
                if (car.onRoad != null)
                  _Detail(
                    icon: Icons.visibility_outlined,
                    text: car.onRoad!.label,
                  ),
              ],
            ),
          ],
          if (car.produced != null) ...[
            const SizedBox(height: 8),
            Center(
              child: _Detail(
                icon: Icons.precision_manufacturing_outlined,
                text: '${formatNumber(car.produced!)} exemplaires fabriqués',
              ),
            ),
          ],
          if (car.location != null) ...[
            const SizedBox(height: 10),
            Center(
              child: _Detail(
                icon: Icons.place_outlined,
                text: car.location!.fromPhoto
                    ? car.location!.label
                    : '${car.location!.label} (téléphone)',
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton(
              onPressed: _sharing ? null : _share,
              style: OutlinedButton.styleFrom(
                foregroundColor: SpotItColors.accent,
                side: const BorderSide(color: SpotItColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const ButtonLabel(
                icon: Icons.ios_share,
                text: 'Partager',
              ),
            ),
          ),
        ],
      ),
      image: CarImage(
        carId: car.id,
        fit: BoxFit.contain,
        zoomable: true,
        box: car.recognition.box,
      ),
      actions: ShowcaseActions(
        primary: OutlinedButton(
          onPressed: _deleting ? null : _delete,
          style: OutlinedButton.styleFrom(
            foregroundColor: SpotItColors.danger,
            side: const BorderSide(color: SpotItColors.danger),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _deleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SpotItColors.danger,
                  ),
                )
              : const ButtonLabel(
                  icon: Icons.delete_outline,
                  text: 'Supprimer de la bibliothèque',
                ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: SpotItColors.accent),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: SpotItColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
