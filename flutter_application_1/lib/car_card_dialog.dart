import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'car_image.dart';
import 'car_service.dart';
import 'car_showcase_dialog.dart';
import 'scanned_car.dart';
import 'spot_it_theme.dart';
import 'spot_it_widgets.dart';
import 'toast.dart';

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

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cette photo ?',
      message: 'Elle sera retirée de votre bibliothèque. Cette action est définitive.',
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
      showSpotItToast(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return CarShowcaseDialog(
      label: 'FICHE VOITURE',
      recognition: car.recognition,
      discoveredOn: car.scannedDate,
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
              : const ShowcaseActionLabel(
                  icon: Icons.delete_outline,
                  text: 'Supprimer de la bibliothèque',
                ),
        ),
      ),
    );
  }
}
