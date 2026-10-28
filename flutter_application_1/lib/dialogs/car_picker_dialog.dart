import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/recognition.dart';
import '../services/api.dart';
import '../services/car_service.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/spot_it_widgets.dart';

/// Laisse l'utilisateur chercher la bonne voiture dans toute la liste de l'IA.
Future<Recognition?> showCarPickerDialog(BuildContext context) {
  return showDialog<Recognition>(
    context: context,
    builder: (_) => const _CarPickerDialog(),
  );
}

class _CarPickerDialog extends StatefulWidget {
  const _CarPickerDialog();

  @override
  State<_CarPickerDialog> createState() => _CarPickerDialogState();
}

class _CarPickerDialogState extends State<_CarPickerDialog> {
  final Future<List<Recognition>> _cars = CarService.catalog();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SpotItDialog(
      title: Text(
        'Quelle est cette voiture ?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Choisissez-la : l'IA apprendra à la reconnaître.",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: SpotItColors.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Marque, modèle… ex. BMW M4',
                hintStyle: GoogleFonts.inter(color: SpotItColors.disabledText),
                prefixIcon:
                    const Icon(Icons.search, color: SpotItColors.secondaryText),
                filled: true,
                fillColor: SpotItColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: SpotItColors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Recognition>>(
                future: _cars,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _Message(errorMessage(snapshot.error!));
                  }
                  final cars = snapshot.data;
                  if (cars == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final found = cars.where((car) => car.matches(_query));
                  if (found.isEmpty) {
                    return const _Message('Aucune voiture ne correspond');
                  }
                  final shown = found.take(50).toList();
                  return ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final car = shown[index];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        title: Text(
                          '${car.brand} ${car.model}',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        subtitle: Text(
                          car.years,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: SpotItColors.secondaryText,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, car),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: SpotItColors.secondaryText),
      ),
    );
  }
}
