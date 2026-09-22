import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'spot_it_theme.dart';

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
  bool _isConnected = false;
  bool _isEditing = false;
  bool _obscurePassword = true;
  String _savedName = 'Victorien';
  String _savedEmail = 'victorien@example.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitAuth() {
    if (!(_authFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _savedName = _mode == _AuthMode.register
          ? _nameController.text.trim()
          : 'Victorien';
      _savedEmail = _emailController.text.trim();
      _isConnected = true;
      _isEditing = false;
      _passwordController.clear();
    });
  }

  void _startEditing() {
    _nameController.text = _savedName;
    _emailController.text = _savedEmail;
    setState(() => _isEditing = true);
  }

  void _saveProfile() {
    if (!(_profileFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _savedName = _nameController.text.trim();
      _savedEmail = _emailController.text.trim();
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations mises à jour')),
    );
  }

  void _logout() {
    setState(() {
      _isConnected = false;
      _isEditing = false;
      _mode = _AuthMode.login;
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SpotItColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SpotItColors.border),
        ),
        title: Text(
          'Supprimer le compte ?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Cette action est définitive. Toutes vos données seront supprimées.',
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
    if (confirmed == true) {
      _logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte supprimé')),
        );
      }
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
                _SettingsHeader(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _isConnected
                          ? _buildConnectedView()
                          : _buildAuthView(),
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
          Text(
            isLogin
                ? 'Connectez-vous pour retrouver votre profil.'
                : 'Enregistrez vos informations pour commencer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SpotItColors.secondaryText,
            ),
          ),
          const SizedBox(height: 28),
          if (!isLogin) ...[
            _SpotItTextField(
              controller: _nameController,
              label: 'Nom ou pseudo',
              icon: Icons.badge_outlined,
              validator: (value) => (value == null || value.trim().length < 2)
                  ? 'Saisissez au moins 2 caractères'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          _SpotItTextField(
            controller: _emailController,
            label: 'Adresse e-mail',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
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
            validator: (value) => (value == null || value.length < 6)
                ? 'Le mot de passe doit contenir au moins 6 caractères'
                : null,
          ),
          const SizedBox(height: 22),
          _PrimaryButton(
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
            _SpotItTextField(
              controller: _nameController,
              label: 'Nom ou pseudo',
              icon: Icons.badge_outlined,
              validator: (value) => (value == null || value.trim().length < 2)
                  ? 'Saisissez au moins 2 caractères'
                  : null,
            ),
            const SizedBox(height: 14),
            _SpotItTextField(
              controller: _emailController,
              label: 'Adresse e-mail',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
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
          _savedName,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _savedEmail,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: SpotItColors.secondaryText,
          ),
        ),
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

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
                'Paramètres',
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: SpotItColors.accent,
          foregroundColor: SpotItColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
