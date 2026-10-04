// Thaiprompt POS — Customer display (/display/customer) · counter 2nd screen.
//
// Thin in-app host for the pure CustomerDisplayView: NvKiosk frame (no staff
// chrome; long-press the logo 1.5 s + manager PIN to leave) around a
// DisplaySnapshot rebuilt from the live store on every change. The very same
// view runs on a physical second screen (CustomerDisplayApp) fed by
// serialized snapshots, so both always look identical.
//
// A 30 s refresh rebuilds the snapshot even without store changes, so
// time-based rules (promotion happy-hour windows, coupon validity) stay
// current. The thank-you expiry and the promo carousel are timed inside the
// view itself.
//
// by xman studio

import 'dart:async';

import 'package:flutter/material.dart';

import '../display/customer_display_view.dart';
import '../display/display_snapshot.dart';
import '../state/app_scope.dart';
import '../widgets/nova/nova.dart';

class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = DisplaySnapshot.fromStore(AppScope.of(context));
    return NvKiosk(child: CustomerDisplayView(snap: snap));
  }
}
