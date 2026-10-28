import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/spot_it_theme.dart';

const double kContentMaxWidth = 402;

class SpotItPage extends StatelessWidget {
  const SpotItPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpotItColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SpotItIconButton extends StatelessWidget {
  const SpotItIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.radius = 20,
    this.showBorder = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SpotItColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: showBorder
            ? const BorderSide(color: SpotItColors.border)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class SpotItHeader extends StatelessWidget {
  const SpotItHeader({
    required this.title,
    this.subtitle,
    this.titleSize = 22,
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final double titleSize;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 91,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            leading ??
                SpotItIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: SpotItColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

class ButtonLabel extends StatelessWidget {
  const ButtonLabel({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style:
                GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class SpotItPrimaryButton extends StatelessWidget {
  const SpotItPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: SpotItColors.accent,
          foregroundColor: SpotItColors.background,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: ButtonLabel(icon: icon, text: label),
      ),
    );
  }
}

class SpotItDialog extends StatelessWidget {
  const SpotItDialog({
    required this.title,
    required this.content,
    required this.actions,
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SpotItColors.surface,
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: kContentMaxWidth - 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SpotItColors.border),
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Supprimer',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => SpotItDialog(
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: Text(
        message,
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
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
