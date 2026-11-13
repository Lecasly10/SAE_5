import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../dialogs/car_card_dialog.dart';
import '../models/scanned_car.dart';
import '../services/auth_service.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/spot_it_widgets.dart';
import 'settings_page.dart';

/// Carte des voitures repérées, à l'endroit où chaque photo a été prise.
class CarMapPage extends StatefulWidget {
  const CarMapPage({required this.cars, super.key});

  final List<ScannedCar> cars;

  @override
  State<CarMapPage> createState() => _CarMapPageState();
}

class _CarMapPageState extends State<CarMapPage> {
  late List<ScannedCar> _cars =
      widget.cars.where((car) => car.location != null).toList();

  LatLng _point(ScannedCar car) =>
      LatLng(car.location!.latitude, car.location!.longitude);

  Future<void> _open(ScannedCar car) async {
    final deleted = await showCarCardDialog(context, car);
    if (deleted && mounted) {
      setState(() => _cars = _cars.where((c) => c.id != car.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _cars.length;
    return SpotItPage(
      child: Column(
        children: [
          SpotItHeader(
            title: 'Ma carte',
            subtitle: '$count ${count > 1 ? 'voitures placées' : 'voiture placée'}',
          ),
          Expanded(child: _cars.isEmpty ? const _EmptyMap() : _map()),
        ],
      ),
    );
  }

  Widget _map() {
    final points = _cars.map(_point).toList();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: points.first,
          initialZoom: 13,
          initialCameraFit: points.length > 1
              ? CameraFit.coordinates(
                  coordinates: points,
                  padding: const EdgeInsets.all(48),
                  maxZoom: 15,
                )
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'fr.spotit.app',
          ),
          MarkerLayer(
            markers: [
              for (final car in _cars)
                Marker(
                  point: _point(car),
                  width: 40,
                  height: 40,
                  child: _CarMarker(car: car, onTap: () => _open(car)),
                ),
            ],
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('Contributeurs OpenStreetMap'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarMarker extends StatelessWidget {
  const _CarMarker({required this.car, required this.onTap});

  final ScannedCar car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = car.rarity.color;
    return Tooltip(
      message: '${car.recognition.brand} ${car.recognition.model}\n'
          '${car.location!.label}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: SpotItColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
            ],
          ),
          child: Icon(Icons.directions_car, size: 20, color: color),
        ),
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    final consent = AuthService.locationConsent;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 56, color: SpotItColors.accent),
          const SizedBox(height: 18),
          Text(
            'Aucune voiture sur la carte',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            consent
                ? 'Les voitures que vous ajouterez apparaîtront ici, '
                    "à l'endroit où vous les avez photographiées."
                : "Autorisez l'enregistrement de la position dans les "
                    'paramètres pour placer vos prochaines voitures sur la carte.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: SpotItColors.secondaryText,
            ),
          ),
          if (!consent) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              ),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Paramètres'),
              style:
                  TextButton.styleFrom(foregroundColor: SpotItColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}
