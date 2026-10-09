import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'recognition.dart';
import 'spot_it_theme.dart';

Future<T?> showShowcaseDialog<T>(BuildContext context, WidgetBuilder builder) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, _, __) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class CarShowcaseDialog extends StatefulWidget {
  const CarShowcaseDialog({
    required this.label,
    required this.image,
    required this.recognition,
    required this.actions,
    this.discoveredOn,
    super.key,
  });

  final String label;
  final Widget image;
  final Recognition recognition;
  final String? discoveredOn;
  final Widget actions;

  @override
  State<CarShowcaseDialog> createState() => _CarShowcaseDialogState();
}

class _CarShowcaseDialogState extends State<CarShowcaseDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  Animation<double> _stage(double begin, double end) => CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recognition = widget.recognition;
    final stats = [
      if (recognition.years.isNotEmpty) ('PRODUCTION', recognition.years),
      if (widget.discoveredOn != null) ('DÉCOUVERTE', widget.discoveredOn!),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SpotItColors.accent.withValues(alpha: 0.9),
                const Color(0xFF7C5CFF).withValues(alpha: 0.6),
                SpotItColors.accent.withValues(alpha: 0.12),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: SpotItColors.accent.withValues(alpha: 0.18),
                blurRadius: 40,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.5),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [SpotItColors.selectedSurface, SpotItColors.surface],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(label: widget.label),
                  const SizedBox(height: 14),
                  Container(
                    height: 230,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: SpotItColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SpotItColors.border),
                    ),
                    child: widget.image,
                  ),
                  const SizedBox(height: 20),
                  _Reveal(
                    animation: _stage(0.3, 0.6),
                    child: Text(
                      recognition.brand.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: SpotItColors.accent,
                      ),
                    ),
                  ),
                  if (recognition.model.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _Reveal(
                      animation: _stage(0.4, 0.75),
                      child: Text(
                        recognition.model,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 30,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _Reveal(
                    animation: _stage(0.55, 0.95),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (stats.isNotEmpty)
                          Row(
                            children: [
                              for (var i = 0; i < stats.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(
                                  child: _StatTile(
                                    label: stats[i].$1,
                                    value: stats[i].$2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (stats.isNotEmpty) const SizedBox(height: 10),
                        _ConfidenceMeter(
                          value: recognition.confidence,
                          progress: _stage(0.6, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  widget.actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShowcaseActions extends StatelessWidget {
  const ShowcaseActions({required this.primary, super.key});

  final Widget primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SizedBox(height: 52, child: primary)),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: SpotItColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Fermer',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShowcaseActionLabel extends StatelessWidget {
  const ShowcaseActionLabel({required this.icon, required this.text, super.key});

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
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: SpotItColors.accent),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: SpotItColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SpotItColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: SpotItColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.value, required this.progress});

  final int value;
  final Animation<double> progress;

  Color get _color => value >= 70
      ? SpotItColors.accent
      : value >= 40
          ? SpotItColors.warning
          : SpotItColors.danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: SpotItColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'CONFIANCE DE L’IA',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: SpotItColors.secondaryText,
                ),
              ),
              const Spacer(),
              Text(
                '$value %',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              color: SpotItColors.border,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) => FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0.0, 1.0) * progress.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_color.withValues(alpha: 0.6), _color],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
