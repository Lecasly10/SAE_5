import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';
import 'car_card_dialog.dart';
import 'car_image.dart';
import 'car_service.dart';
import 'scanned_car.dart';
import 'settings_page.dart';
import 'spot_it_theme.dart';
import 'spot_it_widgets.dart';
import 'toast.dart';

class CarLibraryPage extends StatefulWidget {
  const CarLibraryPage({super.key});

  @override
  State<CarLibraryPage> createState() => _CarLibraryPageState();
}

class _CarLibraryPageState extends State<CarLibraryPage> {
  List<ScannedCar> _cars = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (AuthService.isLoggedIn) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cars = await CarService.list();
      if (!mounted) return;
      setState(() => _cars = cars);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPreview(ScannedCar car) async {
    final deleted = await showCarCardDialog(context, car);
    if (!deleted || !mounted) return;
    setState(() => _cars = _cars.where((c) => c.id != car.id).toList());
    showSpotItToast(context, 'Photo supprimée de la bibliothèque');
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
    if (!mounted) return;
    if (AuthService.isLoggedIn) {
      _load();
    } else {
      setState(() => _cars = const []);
    }
  }

  Widget _body() {
    if (!AuthService.isLoggedIn) {
      return _LibraryMessage(
        icon: Icons.lock_outline,
        title: 'Connectez-vous',
        message:
            'Votre bibliothèque est liée à votre compte. Connectez-vous pour retrouver vos photos sur tous vos appareils.',
        actionIcon: Icons.login,
        actionLabel: 'Se connecter',
        onAction: _openSettings,
      );
    }
    if (_loading && _cars.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: SpotItColors.accent),
      );
    }
    if (_error != null && _cars.isEmpty) {
      return _LibraryMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Chargement impossible',
        message: _error!,
        actionIcon: Icons.refresh,
        actionLabel: 'Réessayer',
        onAction: _load,
      );
    }
    if (_cars.isEmpty) {
      return _LibraryMessage(
        icon: Icons.menu_book_outlined,
        title: 'Aucune voiture scannée',
        message:
            'Les photos analysées apparaîtront ici et seront gardées sur votre compte.',
        actionIcon: Icons.camera_alt_outlined,
        actionLabel: 'Scanner une voiture',
        onAction: () => Navigator.pop(context),
      );
    }
    return RefreshIndicator(
      color: SpotItColors.accent,
      backgroundColor: SpotItColors.surface,
      onRefresh: _load,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _cars.length,
        itemBuilder: (context, index) => _CarCard(
          key: ValueKey(_cars[index].id),
          car: _cars[index],
          onTap: () => _openPreview(_cars[index]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _cars.length;
    return SpotItPage(
      child: Column(
        children: [
          SpotItHeader(
            title: 'Ma bibliothèque',
            subtitle: AuthService.isLoggedIn
                ? '$count ${count > 1 ? 'voitures scannées' : 'voiture scannée'}'
                : null,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({required this.car, required this.onTap, super.key});

  final ScannedCar car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final recognition = car.recognition;
    return Material(
      color: SpotItColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: SpotItColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: CarImage(key: ValueKey(car.id), carId: car.id)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: SpotItColors.accent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          recognition.brand.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: SpotItColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (recognition.model.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      recognition.model,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    car.scannedDate,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: SpotItColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: SpotItColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: SpotItColors.border),
            ),
            child: Icon(icon, size: 38, color: SpotItColors.accent),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: SpotItColors.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
            style: TextButton.styleFrom(foregroundColor: SpotItColors.accent),
          ),
        ],
      ),
    );
  }
}
