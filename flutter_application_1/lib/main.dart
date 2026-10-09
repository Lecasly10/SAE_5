import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:window_manager/window_manager.dart';

import 'car_library_page.dart';
import 'car_reveal_dialog.dart';
import 'car_service.dart';
import 'framed_image.dart';
import 'recognition.dart';
import 'settings_page.dart';
import 'spot_it_theme.dart';
import 'spot_it_widgets.dart';
import 'toast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const desktop = {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  };
  if (!kIsWeb && desktop.contains(defaultTargetPlatform)) {
    await WindowManager.instance.ensureInitialized();
    await WindowManager.instance.setMinimumSize(const Size(390, 844));
    await WindowManager.instance.setMaximumSize(const Size(390, 844));
    await WindowManager.instance.setSize(const Size(390, 844));
    await WindowManager.instance.center();
  }

  runApp(const SpotItApp());
}

class SpotItApp extends StatelessWidget {
  const SpotItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Spot'It",
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: SpotItColors.background,
      ),
      home: const SpotItHomePage(),
    );
  }
}

class SpotItHomePage extends StatefulWidget {
  const SpotItHomePage({super.key});

  @override
  State<SpotItHomePage> createState() => _SpotItHomePageState();
}

class _SpotItHomePageState extends State<SpotItHomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedBytes;
  bool _analyzing = false;
  DetectionBox? _detectionBox;

  Future<void> _pickImage(ImageSource source) async {
    if (_analyzing) return;
    HapticFeedback.selectionClick();
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = image;
        _selectedBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      _showToast(
        source == ImageSource.camera
            ? "Impossible d'ouvrir l'appareil photo"
            : "Impossible d'ouvrir la galerie",
        isError: true,
      );
    }
  }

  void _clearImage() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedImage = null;
      _selectedBytes = null;
      _detectionBox = null;
    });
  }

  Future<void> _analyze() async {
    final image = _selectedImage;
    final bytes = _selectedBytes;
    if (image == null || bytes == null || _analyzing) return;
    HapticFeedback.mediumImpact();

    setState(() => _analyzing = true);
    try {
      final recognition = await CarService.recognize(image, bytes);
      if (!mounted) return;
      if (recognition.box != null) {
        setState(() => _detectionBox = recognition.box);
        await Future.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
      }
      final choice = await showCarRevealDialog(
        context,
        bytes: bytes,
        recognition: recognition,
      );
      if (!mounted) return;

      switch (choice) {
        case AnalysisChoice.addToLibrary:
          await CarService.upload(image, bytes);
          if (!mounted) return;
          _clearImage();
          _showToast(
            'Voiture ajoutée à votre bibliothèque',
            actionLabel: 'Voir',
            onAction: _openLibrary,
          );
        case AnalysisChoice.login:
          _openSettings();
        case null:
          _clearImage();
      }
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  void _showToast(
    String message, {
    bool isError = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showSpotItToast(
      context,
      message,
      isError: isError,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void _openLibrary() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CarLibraryPage()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedBytes != null;
    return SpotItPage(
      child: Column(
        children: [
          _TopNavigation(onLibrary: _openLibrary, onSettings: _openSettings),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              child: Column(
                children: [
                  Text(
                    'Scannez la voiture',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ScannerViewfinder(
                    bytes: _selectedBytes,
                    box: _detectionBox,
                    onClear: _analyzing ? null : _clearImage,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoSourceButton(
                          icon: Icons.photo_camera_rounded,
                          label: 'Prendre une photo',
                          caption: 'Appareil photo',
                          primary: true,
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PhotoSourceButton(
                          icon: Icons.add_photo_alternate_rounded,
                          label: 'Insérer une photo',
                          caption: 'Depuis la galerie',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _AnalyzeButton(
                    enabled: hasImage,
                    loading: _analyzing,
                    onPressed: _analyze,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    hasImage
                        ? 'Votre photo est prête à être analysée'
                        : "Sélectionnez ou prenez un cliché pour démarrer l'analyse",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: hasImage
                          ? SpotItColors.secondaryText
                          : SpotItColors.disabledText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.onLibrary, required this.onSettings});

  final VoidCallback onLibrary;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 91,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SpotItIconButton(
              icon: Icons.menu_book_outlined,
              onTap: onLibrary,
              size: 42,
              radius: 10,
            ),
            Text(
              "Spot'It",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SpotItIconButton(
              icon: Icons.settings_outlined,
              onTap: onSettings,
              size: 40,
              radius: 20,
              showBorder: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerViewfinder extends StatelessWidget {
  const _ScannerViewfinder({
    required this.bytes,
    required this.box,
    required this.onClear,
  });

  final Uint8List? bytes;
  final DetectionBox? box;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.36).clamp(240.0, 340.0);
    final hasImage = bytes != null;

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasImage
              ? SpotItColors.accent.withValues(alpha: 0.5)
              : SpotItColors.border,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SpotItColors.surface, SpotItColors.background],
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: hasImage
            ? Stack(
                key: const ValueKey('photo'),
                fit: StackFit.expand,
                children: [
                  FramedImage(
                    bytes: bytes!,
                    box: box,
                    fit: BoxFit.cover,
                    revealDelay: Duration.zero,
                  ),
                  CustomPaint(
                    painter: _CornerBracketsPainter(SpotItColors.accent),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _CircleIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Retirer la photo',
                      onTap: onClear,
                    ),
                  ),
                ],
              )
            : Stack(
                key: const ValueKey('empty'),
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _CornerBracketsPainter(
                      SpotItColors.disabledText.withValues(alpha: 0.7),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SpotItColors.accent.withValues(alpha: 0.08),
                            border: Border.all(
                              color: SpotItColors.accent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.directions_car_filled_rounded,
                            size: 38,
                            color: SpotItColors.accent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cadrez la voiture',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prenez une photo ou choisissez-en une',
                          style: GoogleFonts.inter(
                            fontSize: 12,
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 20.0;
    const length = 26.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(w - inset - length, inset)
      ..lineTo(w - inset, inset)
      ..lineTo(w - inset, inset + length)
      ..moveTo(inset, h - inset - length)
      ..lineTo(inset, h - inset)
      ..lineTo(inset + length, h - inset)
      ..moveTo(w - inset - length, h - inset)
      ..lineTo(w - inset, h - inset)
      ..lineTo(w - inset, h - inset - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PhotoSourceButton extends StatefulWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_PhotoSourceButton> createState() => _PhotoSourceButtonState();
}

class _PhotoSourceButtonState extends State<_PhotoSourceButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final foreground = primary ? SpotItColors.background : Colors.white;
    final captionColor = primary
        ? SpotItColors.background.withValues(alpha: 0.65)
        : SpotItColors.secondaryText;
    final radius = BorderRadius.circular(24);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: primary
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3CFFE2), Color(0xFF00C9AE)],
                )
              : null,
          color: primary ? null : SpotItColors.surface,
          border: Border.all(
            color: primary ? Colors.transparent : SpotItColors.border,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: SpotItColors.accent.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary
                          ? SpotItColors.background.withValues(alpha: 0.14)
                          : SpotItColors.accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 24,
                      color: primary
                          ? SpotItColors.background
                          : SpotItColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.caption,
                    maxLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: captionColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = enabled || loading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: SpotItColors.accent,
          foregroundColor: SpotItColors.background,
          disabledBackgroundColor: loading
              ? SpotItColors.accent.withValues(alpha: 0.85)
              : SpotItColors.disabledSurface.withValues(alpha: 0.60),
          disabledForegroundColor:
              loading ? SpotItColors.background : SpotItColors.disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color:
                  active ? SpotItColors.accent : SpotItColors.disabledBorder,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: SpotItColors.background,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.center_focus_strong, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Analyser la photo',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
