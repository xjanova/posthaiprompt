// Thaiprompt POS — Android entry point
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'routes/app_router.dart';
import 'theme/tp_theme.dart';
import 'theme/tp_tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
