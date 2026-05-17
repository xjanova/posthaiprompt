// Thaiprompt POS — entry point (Windows · Android · iOS)
// by xman studio

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

import 'routes/app_router.dart';
import 'theme/tp_theme.dart';
import 'theme/tp_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows: real Mica/Acrylic via Win32 DwmExtendFrameIntoClientArea.
  // On Android/iOS we fall through and use BackdropFilter blur on glass cards.
  if (!kIsWeb && Platform.isWindows) {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0x80F5FBFE), // 50% bgCream tint
    );
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: TpTokens.bg2,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ThaipromptPosApp());
}

class ThaipromptPosApp extends StatelessWidget {
  const ThaipromptPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Thaiprompt POS',
      debugShowCheckedModeBanner: false,
      theme: TpTheme.light(),
      routerConfig: AppRouter.router,
      // Note: text-scaling clamp moved out of MaterialApp.builder — that pattern
      // tripped the framework's "_dependents.isEmpty" assertion in Flutter 3.41
      // by wrapping the router's own MediaQuery. Apply per-screen if needed.
    );
  }
}
