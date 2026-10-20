import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../dialogs/car_reveal_dialog.dart';
import '../dialogs/car_unrecognized_dialog.dart';
import '../models/recognition.dart';
import '../services/car_service.dart';
import '../theme/spot_it_theme.dart';
import '../widgets/analyze_button.dart';
import '../widgets/photo_source_button.dart';
import '../widgets/scanner_viewfinder.dart';
import '../widgets/spot_it_widgets.dart';
import '../widgets/toast.dart';
import 'car_library_page.dart';
import 'settings_page.dart';

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
      showSpotItToast(
        context,
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
      final result = await CarService.recognize(image, bytes);
      if (!mounted) return;
      if (result.box != null) {
        setState(() => _detectionBox = result.box);
        await Future.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
      }
      final recognition = result.recognition;
      if (recognition == null) {
        await showUnrecognizedDialog(context, bytes: bytes, result: result);
        if (!mounted) return;
        _clearImage();
        return;
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
          showSpotItToast(
            context,
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
      showSpotItToast(context, e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
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
          SpotItHeader(
            title: "Spot'It",
            titleSize: 24,
            leading: SpotItIconButton(
              icon: Icons.menu_book_outlined,
              onTap: _openLibrary,
              size: 42,
              radius: 10,
            ),
            trailing: SpotItIconButton(
              icon: Icons.settings_outlined,
              onTap: _openSettings,
              showBorder: true,
            ),
          ),
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
                  ScannerViewfinder(
                    bytes: _selectedBytes,
                    box: _detectionBox,
                    onClear: _analyzing ? null : _clearImage,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: PhotoSourceButton(
                          icon: Icons.photo_camera_rounded,
                          label: 'Prendre une photo',
                          caption: 'Appareil photo',
                          primary: true,
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PhotoSourceButton(
                          icon: Icons.add_photo_alternate_rounded,
                          label: 'Insérer une photo',
                          caption: 'Depuis la galerie',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AnalyzeButton(
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
