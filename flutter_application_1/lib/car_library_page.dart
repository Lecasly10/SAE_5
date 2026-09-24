import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'scanned_car.dart';
import 'spot_it_theme.dart';

class CarLibraryPage extends StatelessWidget {
  const CarLibraryPage({
    required this.cars,
    super.key,
  });

  final List<ScannedCar> cars;

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
                _LibraryHeader(
                  count: cars.length,
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: cars.isEmpty
                      ? const _EmptyLibrary()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: cars.length,
                          itemBuilder: (context, index) =>
                              _CarCard(car: cars[index]),
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

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.count, required this.onBack});

  final int count;
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ma bibliothèque',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$count ${count > 1 ? 'voitures scannées' : 'voiture scannée'}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: SpotItColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

}

class _CarCard extends StatelessWidget {
  const _CarCard({required this.car});

  final ScannedCar car;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpotItColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.file(
              File(car.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: SpotItColors.selectedSurface,
                child: const Icon(
                  Icons.directions_car_filled,
                  size: 46,
                  color: SpotItColors.disabledText,
                ),
              ),
            ),
          ),
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
                    Text(
                      'RECONNU PAR L’IA',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: SpotItColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  car.recognizedName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(car.scannedAt),
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
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

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
            child: const Icon(
              Icons.menu_book_outlined,
              size: 38,
              color: SpotItColors.accent,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Aucune voiture scannée',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les véhicules analysés apparaîtront ici avec le modèle reconnu par l’IA.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: SpotItColors.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scanner une voiture'),
            style: TextButton.styleFrom(foregroundColor: SpotItColors.accent),
          ),
        ],
      ),
    );
  }
}
