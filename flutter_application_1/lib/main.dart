import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:window_manager/window_manager.dart';

import 'car_library_page.dart';
import 'scanned_car.dart';
import 'settings_page.dart';
import 'spot_it_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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

enum PhotoSource { camera, gallery }

class SpotItHomePage extends StatefulWidget {
  const SpotItHomePage({super.key});

  @override
  State<SpotItHomePage> createState() => _SpotItHomePageState();
}

class _SpotItHomePageState extends State<SpotItHomePage> {
  final ImagePicker _picker = ImagePicker();
  PhotoSource _source = PhotoSource.camera;
  XFile? _selectedImage;
  final List<ScannedCar> _scannedCars = [];

  Future<void> _selectSource(PhotoSource source) async {
    setState(() => _source = source);
    final image = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 92,
    );
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  void _analyze() {
    if (_selectedImage == null) return;
    final imagePath = _selectedImage!.path;
    if (!_scannedCars.any((car) => car.imagePath == imagePath)) {
      _scannedCars.insert(
        0,
        ScannedCar(
          imagePath: imagePath,
          // Remplacer ce texte par le résultat réel renvoyé par le modèle IA.
          recognizedName: 'Modèle reconnu par l’IA',
          scannedAt: DateTime.now(),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voiture ajoutée à la bibliothèque')),
    );
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CarLibraryPage(
          cars: List.unmodifiable(_scannedCars),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: Column(
              children: [
                _TopNavigation(onLibrary: _openLibrary),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: Column(
                      children: [
                        Text(
                          'Scannez la voiture',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ScannerViewfinder(image: _selectedImage),
                        const SizedBox(height: 24),
                        _SourceSelector(
                          selected: _source,
                          onSelected: _selectSource,
                        ),
                        const SizedBox(height: 24),
                        _AnalyzeButton(
                          enabled: _selectedImage != null,
                          onPressed: _analyze,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedImage == null
                              ? "Sélectionnez ou prenez un cliché pour démarrer l'analyse"
                              : "Votre photo est prête à être analysée",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _selectedImage == null
                                ? SpotItColors.disabledText
                                : SpotItColors.secondaryText,
                          ),
                        ),
                      ],
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
}

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({required this.onLibrary});

  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 91,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
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
            _NavButton(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage(),
                ),
              ),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.radius,
    this.showBorder = false,
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

class _ScannerViewfinder extends StatelessWidget {
  const _ScannerViewfinder({required this.image});

  final XFile? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 330,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SpotItColors.border),
      ),
      child: image == null
          ? const Center(
              child: Icon(
                Icons.photo_camera,
                size: 142,
                color: Color(0xFF444448),
              ),
            )
          : Image.file(File(image!.path), fit: BoxFit.cover),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({required this.selected, required this.onSelected});

  final PhotoSource selected;
  final ValueChanged<PhotoSource> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: SpotItColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpotItColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SourceOption(
              label: 'Prendre une photo',
              icon: Icons.camera_alt_outlined,
              selected: selected == PhotoSource.camera,
              onTap: () => onSelected(PhotoSource.camera),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SourceOption(
              label: 'Insérer une photo',
              icon: Icons.add_photo_alternate_outlined,
              selected: selected == PhotoSource.gallery,
              onTap: () => onSelected(PhotoSource.gallery),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SpotItColors.accent
        : SpotItColors.secondaryText;
    return Material(
      color: selected ? SpotItColors.selectedSurface : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: SpotItColors.accent)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  const _AnalyzeButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.center_focus_strong, size: 18),
        label: Text(
          'Analyser la photo',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: SpotItColors.accent,
          foregroundColor: SpotItColors.background,
          disabledBackgroundColor:
              SpotItColors.disabledSurface.withOpacity(0.60),
          disabledForegroundColor: SpotItColors.disabledText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: enabled
                  ? SpotItColors.accent
                  : SpotItColors.disabledBorder,
            ),
          ),
        ),
      ),
    );
  }
}
