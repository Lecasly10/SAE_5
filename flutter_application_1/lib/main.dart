import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/home_page.dart';
import 'theme/spot_it_theme.dart';

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
