// Thaiprompt POS — Dependency scope for the global store.
//
// Wraps the app in an InheritedNotifier so any screen can reach the PosStore:
//   • AppScope.of(context)    → subscribe (rebuilds this widget on changes)
//   • AppScope.read(context)  → one-shot read for event handlers (no rebuild)
//
// Zero third-party state-management dependency — just Flutter primitives.
//
// by xman studio

import 'package:flutter/widgets.dart';

import 'pos_store.dart';

class AppScope extends InheritedNotifier<PosStore> {
  const AppScope({super.key, required PosStore store, required super.child})
      : super(notifier: store);

  /// Subscribe: the calling widget rebuilds whenever the store notifies.
  static PosStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called with no AppScope ancestor');
    return scope!.notifier!;
  }

  /// One-shot read for callbacks — does NOT subscribe to rebuilds.
  static PosStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.read() called with no AppScope ancestor');
    return scope!.notifier!;
  }
}
