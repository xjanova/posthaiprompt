// Thaiprompt POS — Standalone customer-display app (secondary engine).
//
// Runs on a physical second screen — a separate Flutter engine / isolate on
// Windows' second monitor or an Android Presentation display — where there is
// no PosStore, no router and no plugins: only [DisplaySnapshot]s streamed
// from the main app. Renders [CustomerDisplayView] for the latest snapshot.
//
// Touches no plugin / platform channel: the caller owns the transport and
// hands this widget a plain Dart stream.
//
// by xman studio

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../theme/nv_tokens.dart';
import '../theme/tp_theme.dart';
import '../widgets/nova/nv_art.dart';
import 'customer_display_view.dart';
import 'display_snapshot.dart';

class CustomerDisplayApp extends StatelessWidget {
  final Stream<DisplaySnapshot> snapshots;
  final DisplaySnapshot? initial;
  const CustomerDisplayApp({super.key, required this.snapshots, this.initial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thai Prompt — จอลูกค้า',
      debugShowCheckedModeBanner: false,
      theme: TpTheme.light(),
      locale: const Locale('th', 'TH'),
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _DisplayHome(snapshots: snapshots, initial: initial ?? DisplaySnapshot.empty()),
    );
  }
}

/// Navy scaffold + StreamBuilder. Keeps the last good snapshot on screen when
/// the stream reports an error (e.g. one undecodable message).
class _DisplayHome extends StatefulWidget {
  final Stream<DisplaySnapshot> snapshots;
  final DisplaySnapshot initial;
  const _DisplayHome({required this.snapshots, required this.initial});

  @override
  State<_DisplayHome> createState() => _DisplayHomeState();
}

class _DisplayHomeState extends State<_DisplayHome> {
  late DisplaySnapshot _last = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Nv.navy950,
      body: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.15,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: StreamBuilder<DisplaySnapshot>(
                  stream: widget.snapshots,
                  initialData: widget.initial,
                  builder: (context, s) {
                    final data = s.data;
                    if (data != null) _last = data;
                    return CustomerDisplayView(snap: _last);
                  },
                ),
              ),
              // same brand mark as the in-app kiosk frame (decorative here —
              // nothing to exit on a customer-only screen)
              Positioned(
                top: 10,
                left: 14,
                child: IgnorePointer(
                  child: Opacity(opacity: 0.9, child: NvArt(NvAssets.logoOnDark, height: 34, width: 120)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
