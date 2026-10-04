// Thaiprompt POS — Local persistence (JSON snapshot on disk).
//
// Why a JSON file and not sqflite? The plain `sqflite` plugin doesn't support
// Windows (our primary POS target) without the FFI variant. `path_provider`
// ships everywhere, so a versioned JSON snapshot in the app-support dir is the
// robust zero-extra-dep choice.
//
// Crash safety: every save writes `<file>.tmp`, flushes, then renames over the
// real file (atomic on NTFS/ext4/APFS), keeping the previous good snapshot as
// `<file>.bak`. load() falls back to the .bak when the main file is missing or
// corrupt, and reports which one it used so the store can warn instead of
// silently starting empty and overwriting sales history.
//
// by xman studio

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum LoadSource { none, main, backup }

class LocalStore {
  static const schemaVersion = 2;

  /// File name under the app-support dir. Defaults to the main state snapshot;
  /// the sync outbox uses its own file ('pos_outbox.json').
  final String fileName;

  /// Test hook: write under this directory instead of the app-support dir.
  final Directory? baseDir;

  File? _file;
  Timer? _debounce;
  Future<void> _writing = Future.value();
  LoadSource lastLoadSource = LoadSource.none;

  LocalStore({this.fileName = 'pos_state.json', this.baseDir});

  Future<File> _resolve() async {
    if (_file != null) return _file!;
    final dir = baseDir ?? await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _file = File(p.join(dir.path, fileName));
  }

  Future<Map<String, dynamic>?> _read(File f) async {
    if (!await f.exists()) return null;
    final raw = await f.readAsString();
    if (raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  /// Returns the persisted snapshot (main file, else the last good backup), or
  /// `null` on a genuine first run.
  Future<Map<String, dynamic>?> load() async {
    final f = await _resolve();
    try {
      final main = await _read(f);
      if (main != null) {
        lastLoadSource = LoadSource.main;
        return main;
      }
    } catch (e) {
      debugPrint('[LocalStore] main snapshot unreadable ($e) — trying backup');
      // Keep the corrupt file for forensics instead of overwriting it later.
      try {
        await f.copy('${f.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
      } catch (_) {}
    }
    try {
      final bak = await _read(File('${f.path}.bak'));
      if (bak != null) {
        lastLoadSource = LoadSource.backup;
        return bak;
      }
    } catch (e) {
      debugPrint('[LocalStore] backup unreadable ($e)');
    }
    lastLoadSource = LoadSource.none;
    return null;
  }

  /// Persist now — serialised so two saves never interleave on disk.
  Future<void> save(Map<String, dynamic> snapshot) {
    final encoded = jsonEncode(snapshot);
    return _writing = _writing.then((_) => _write(encoded));
  }

  Future<void> _write(String encoded) async {
    try {
      final f = await _resolve();
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(encoded, flush: true);
      if (await f.exists()) {
        try {
          await f.copy('${f.path}.bak');
        } catch (_) {}
      }
      await tmp.rename(f.path);
    } catch (e) {
      // Never throw into the UI thread; the next mutation retries.
      debugPrint('[LocalStore] save failed: $e');
    }
  }

  /// Coalesce rapid mutations (qty stepper taps) into one write ~400ms later.
  void saveDebounced(Map<String, dynamic> Function() snapshot) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      save(snapshot());
    });
  }

  void dispose() => _debounce?.cancel();
}
