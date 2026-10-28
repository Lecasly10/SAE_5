import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/car_service.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/spot_it_widgets.dart';
import '../widgets/toast.dart';

enum _AuthMode { login, register }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _isEditing = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Lance une action sur le serveur, rafraîchit la page puis affiche
  /// [done], ou l'erreur. Renvoie vrai si tout s'est bien passé.
  Future<bool> _call(Future<void> Function() action, {String? done}) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showSpotItToast(context, errorMessage(e), isError: true);
      return false;
    }
    if (!mounted) return false;
    setState(() {});
    if (done != null) showSpotItToast(context, done);
    return true;
  }

  Future<void> _submitAuth() async {
    if (!(_authFormKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ok = await _call(() => _mode == _AuthMode.login
        ? AuthService.login(email, password)
        : AuthService.register(_nameController.text.trim(), email, password));
    if (ok) {
      _isEditing = false;
      _passwordController.clear();
    }
  }

  void _startEditing() {
    _nameController.text = AuthService.name ?? '';
    _emailController.text = AuthService.email ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    final ok = await _call(
      () => AuthService.updateAccount(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      ),
      done: 'Informations mises à jour',
    );
    if (ok) setState(() => _isEditing = false);
  }

  void _resetForm() {
    CarService.clearCache();
    setState(() {
      _isEditing = false;
      _mode = _AuthMode.login;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _logout() {
    AuthService.logout();
    _resetForm();
  }

  Future<void> _setTrainingConsent(bool value) async {
    if (!value) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Retirer votre accord ?',
        confirmLabel: 'Retirer',
        message:
            "Les photos gardées pour entraîner l'IA seront supprimées. Vos voitures restent dans votre bibliothèque mais ne serviront plus à l'entraînement.",
      );
      if (!confirmed) return;
    }
    await _call(
      () => AuthService.updateAccount(trainingConsent: value),
      done: value ? "Merci ! Vos photos aideront l'IA" : 'Accord retiré',
    );
  }

  void _showTrainingInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => SpotItDialog(
        title: Text(
          "Entraînement de l'IA avec vos photos",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Text(
            kTrainingConsentText,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: SpotItColors.secondaryText,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer le compte ?',
      message:
          'Cette action est définitive. Votre compte, vos voitures et vos photos seront supprimés.',
    );
    if (confirmed &&
        await _call(AuthService.deleteAccount, done: 'Compte supprimé')) {
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SpotItPage(
      child: Column(
        children: [
          const SpotItHeader(title: 'Paramètres'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: AuthService.isLoggedIn
                    ? _buildConnectedView()
                    : _buildAuthView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthView() {
    final isLogin = _mode == _AuthMode.login;
    return Form(
      key: _authFormKey,
      child: Column(
        key: ValueKey(_mode),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AccountIcon(icon: Icons.person_outline),
          const SizedBox(height: 20),
          Text(
            isLogin ? 'Bienvenue !' : 'Créer un compte',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _Caption(
            isLogin
                ? 'Connectez-vous pour retrouver votre profil.'
                : 'Enregistrez vos informations pour commencer.',
          ),
          const SizedBox(height: 28),
          if (!isLogin) ...[
            _nameField(),
            const SizedBox(height: 14),
          ],
          _emailField(),
          const SizedBox(height: 14),
          _SpotItTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: SpotItColors.secondaryText,
              ),
            ),
            validator: (value) => (value == null || value.length < 8)
                ? 'Le mot de passe doit contenir au moins 8 caractères'
                : null,
          ),
          const SizedBox(height: 22),
          SpotItPrimaryButton(
            label: isLogin ? 'Se connecter' : "S'inscrire",
            icon: isLogin ? Icons.login : Icons.person_add_alt_1,
            onPressed: _submitAuth,
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              setState(() {
                _mode = isLogin ? _AuthMode.register : _AuthMode.login;
                _passwordController.clear();
              });
            },
            child: Text(
              isLogin
                  ? "Pas encore de compte ? S'inscrire"
                  : 'Déjà un compte ? Se connecter',
              style: GoogleFonts.inter(
                color: SpotItColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView() {
    if (_isEditing) {
      return Form(
        key: _profileFormKey,
        child: Column(
          key: const ValueKey('edit'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Modifier mes informations'),
            const SizedBox(height: 20),
            _nameField(),
            const SizedBox(height: 14),
            _emailField(),
            const SizedBox(height: 22),
            SpotItPrimaryButton(
              label: 'Enregistrer',
              icon: Icons.check,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: _outlinedButtonStyle(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('profile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AccountIcon(icon: Icons.person),
        const SizedBox(height: 16),
        Text(
          AuthService.name ?? '',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        _Caption(AuthService.email ?? ''),
        const SizedBox(height: 28),
        _ProfileAction(
          icon: Icons.edit_outlined,
          title: 'Modifier mes informations',
          subtitle: 'Nom, pseudo et adresse e-mail',
          onTap: _startEditing,
        ),
        const SizedBox(height: 12),
        _ProfileAction(
          icon: Icons.logout,
          title: 'Se déconnecter',
          subtitle: 'Revenir au mode non connecté',
          onTap: _logout,
        ),
        const SizedBox(height: 28),
        _sectionTitle('Confidentialité'),
        const SizedBox(height: 12),
        _TrainingConsentTile(
          value: AuthService.trainingConsent,
          onChanged: _setTrainingConsent,
          onMore: _showTrainingInfo,
        ),
        const SizedBox(height: 28),
        _sectionTitle('Zone sensible', color: SpotItColors.danger),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _deleteAccount,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Supprimer mon compte'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SpotItColors.danger,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: SpotItColors.danger),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nameField() => _SpotItTextField(
        controller: _nameController,
        label: 'Nom ou pseudo',
        icon: Icons.badge_outlined,
        validator: _validateName,
      );

  Widget _emailField() => _SpotItTextField(
        controller: _emailController,
        label: 'Adresse e-mail',
        icon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
      );

  String? _validateName(String? value) {
    return (value == null || value.trim().length < 2)
        ? 'Saisissez au moins 2 caractères'
        : null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    return !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? 'Saisissez une adresse e-mail valide'
        : null;
  }

  Widget _sectionTitle(String text, {Color color = Colors.white}) => Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );

  ButtonStyle _outlinedButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: SpotItColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
}

const kTrainingConsentText =
    "Si vous activez cette option, Spot'It conserve les photos que vous ajoutez "
    "à votre bibliothèque ou que vous corrigez, avec le modèle de voiture "
    "choisi. Elles servent uniquement à améliorer la reconnaissance des "
    'voitures.\n\n'
    "• Les photos sont recadrées sur la voiture avant l'entraînement.\n"
    '• Elles ne sont jamais publiées, vendues ni partagées.\n'
    "• Ce choix est facultatif : sans lui, l'application fonctionne de la "
    'même façon.\n'
    '• Vous pouvez retirer votre accord à tout moment depuis cette page. Les '
    "photos gardées pour l'entraînement sont alors supprimées et ne servent "
    "plus aux entraînements suivants (une IA déjà entraînée ne peut pas "
    'oublier une photo).\n\n'
    'Évitez les photos où l’on reconnaît des personnes.\n\n'
    'Base légale : votre consentement (article 6.1.a du RGPD).';

class _TrainingConsentTile extends StatelessWidget {
  const _TrainingConsentTile({
    required this.value,
    required this.onChanged,
    required this.onMore,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      decoration: BoxDecoration(
        color: SpotItColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Autoriser l'entraînement de l'IA avec mes photos",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: SpotItColors.accent,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              "Vos photos de voitures confirmées sont conservées pour "
              "apprendre à l'IA à mieux les reconnaître. Facultatif, "
              'modifiable à tout moment.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: SpotItColors.secondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: onMore,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('En savoir plus'),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: SpotItColors.secondaryText,
      ),
    );
  }
}

class _AccountIcon extends StatelessWidget {
  const _AccountIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: SpotItColors.selectedSurface,
          shape: BoxShape.circle,
          border: Border.all(color: SpotItColors.accent),
        ),
        child: Icon(icon, size: 38, color: SpotItColors.accent),
      ),
    );
  }
}

class _SpotItTextField extends StatelessWidget {
  const _SpotItTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: SpotItColors.secondaryText),
        prefixIcon: Icon(icon, color: SpotItColors.secondaryText),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: SpotItColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpotItColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpotItColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: SpotItColors.accent),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SpotItColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: SpotItColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SpotItColors.selectedSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SpotItColors.accent, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: SpotItColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: SpotItColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
