// Thaiprompt POS — entry point (Windows · Android · iOS)
// by xman studio

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/api/api_client.dart';
import 'core/api/api_config.dart';
import 'core/api/pos_api.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/token_storage.dart';
import 'core/sync/outbox.dart';
import 'core/sync/sync_service.dart';
import 'routes/app_router.dart';
import 'state/app_scope.dart';
import 'state/pos_store.dart';
import 'theme/tp_theme.dart';
import 'theme/nv_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot the reactive store from disk before the first frame so persisted
  // sales/stock are present immediately. The seed catalog loads synchronously,
  // so even a brand-new install is usable from frame one.
  final store = PosStore();
  await store.init();

  // ── Real API + offline-first sync stack (main.thaiprompt.online, Sanctum) ──
  // Built after store.init() so the persisted server config is applied. Every
  // step is non-fatal: if the server is unreachable the POS runs fully offline.
  // Ensure a stable per-install device id for the terminal headers (X-Device-ID).
  if (store.deviceId.isEmpty) {
    store.deviceId = 'pos-${newOutboxId()}';
    await store.flush();
  }
  final tokens = TokenStorage();
  final apiConfig = ApiConfig(
    baseUrl: store.serverBaseUrl,
    productKey: store.productKey,
    deviceId: store.deviceId,
  );
  final apiClient = ApiClient(config: apiConfig, tokens: tokens);
  final posApi = PosApi(apiClient, apiConfig);
  final outbox = OutboxQueue();
  await outbox.load();
  final sync = SyncService(api: posApi, config: apiConfig, outbox: outbox)..store = store;
  final auth = AuthRepository(api: posApi, tokens: tokens);
  await auth.restore();
  store.sync = sync;
  store.auth = auth;
  sync.start(); // periodic + on-demand; no-ops until the terminal is paired

  // Windows: real Mica/Acrylic via Win32 DwmExtendFrameIntoClientArea.
  // On Android/iOS we fall through and use BackdropFilter blur on glass cards.
  if (!kIsWeb && Platform.isWindows) {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0xCC070D20), // Nova navy tint behind the title bar
    );
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Nv.navy900,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(ThaipromptPosApp(store: store));
}

class ThaipromptPosApp extends StatefulWidget {
  final PosStore store;
  const ThaipromptPosApp({super.key, required this.store});

  @override
  State<ThaipromptPosApp> createState() => _ThaipromptPosAppState();
}

class _ThaipromptPosAppState extends State<ThaipromptPosApp> {
  // Built once: the router listens to the store for auth/role redirects.
  late final GoRouter _router = AppRouter.create(widget.store);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AppScope exposes the store to the whole tree via InheritedNotifier — every
    // screen reaches it with AppScope.of(context) / AppScope.read(context).
    return AppScope(
      store: widget.store,
      child: MaterialApp.router(
        title: 'Thai Prompt POS',
        debugShowCheckedModeBanner: false,
        theme: TpTheme.light(),
        routerConfig: _router,
        // Thai Material strings (date picker, text selection, tooltips).
        locale: const Locale('th', 'TH'),
        supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
