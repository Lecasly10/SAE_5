import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/spot_it_theme.dart';
import '../widgets/spot_it_widgets.dart';

/// Demande le mot de passe avant de supprimer le compte. Renvoie le mot de
/// passe, ou null si l'utilisateur annule.
Future<String?> showDeleteAccountDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_password.text.isNotEmpty) Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return SpotItDialog(
      title: Text(
        'Supprimer le compte ?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cette action est définitive. Votre compte, vos voitures et vos photos seront supprimés.',
            style: GoogleFonts.inter(color: SpotItColors.secondaryText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: true,
            onSubmitted: (_) => _confirm(),
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: GoogleFonts.inter(color: SpotItColors.secondaryText),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: SpotItColors.secondaryText,
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: SpotItColors.danger),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _confirm,
          style: TextButton.styleFrom(foregroundColor: SpotItColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
