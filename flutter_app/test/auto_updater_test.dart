// Updater against xman4289.com: offer parsing (host / sha / size rules),
// version compare, and the verified download (size, SHA-256, redirects,
// non-file answers) against a loopback HTTP server.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_thaiprompt/services/auto_updater.dart';

final _sha = 'a' * 64;

Map<String, dynamic> offer({
  bool hasUpdate = true,
  String latest = '2.0.3',
  String url = 'https://xman4289.com/apps/thaiprompt-pos/download/2.0.3',
  String? sha,
  Object size = 91111935,
  String changelog = '',
}) =>
    {
      'has_update': hasUpdate,
      'latest_version': latest,
      'download_url': url,
      'changelog': changelog,
      'sha256': sha ?? _sha,
      'file_size': size,
      'filename': 'thaiprompt-pos-2.0.3.apk',
    };

void main() {
  group('offer parsing', () {
    test('a verifiable offer from xman4289.com', () {
      final i = UpdateInfo.fromCheck(offer(), currentVersion: '2.0.2');
      expect(i.hasUpdate, isTrue);
      expect(i.hasInstaller, isTrue);
      expect(i.latestVersion, '2.0.3');
      expect(i.tag, 'v2.0.3');
      expect(i.sizeBytes, 91111935);
    });

    test('no update / same version', () {
      expect(UpdateInfo.fromCheck(offer(hasUpdate: false), currentVersion: '2.0.2').hasUpdate, isFalse);
      expect(UpdateInfo.fromCheck(offer(latest: '2.0.2'), currentVersion: '2.0.2').hasUpdate, isFalse);
    });

    test('downloads off xman4289.com or unverifiable are refused (update still reported)', () {
      for (final bad in [
        offer(url: 'http://xman4289.com/apps/x/download/2.0.3'),
        offer(url: 'https://evil.example/apps/x.apk'),
        offer(url: 'https://xman4289.com.evil.example/x.apk'),
        offer(url: 'https://user:pw@xman4289.com/x.apk'),
        offer(url: 'https://xman4289.com:8443/x.apk'),
        offer(sha: 'xyz'),
        offer(size: 0),
        offer(size: 2 * 1024 * 1024 * 1024),
      ]) {
        final i = UpdateInfo.fromCheck(bad, currentVersion: '2.0.2');
        expect(i.hasUpdate, isTrue, reason: '$bad');
        expect(i.hasInstaller, isFalse, reason: '$bad');
      }
      expect(UpdateInfo.fromCheck(offer(url: 'https://www.xman4289.com/x.apk'), currentVersion: '2.0.2').hasInstaller, isTrue);
      expect(UpdateInfo.fromCheck(offer(size: '1024'), currentVersion: '2.0.2').sizeBytes, 1024);
    });

    test('release notes lose links and markdown', () {
      final i = UpdateInfo.fromCheck(
          offer(changelog: '## มีอะไรใหม่\n**เครื่องพิมพ์**\nดูที่ https://example.com\nFull Changelog: x'),
          currentVersion: '2.0.2');
      expect(i.releaseNotes, 'มีอะไรใหม่\nเครื่องพิมพ์');
    });

    test('version compare', () {
      expect(UpdateInfo.isNewer('2.0.10', '2.0.9'), isTrue);
      expect(UpdateInfo.isNewer('v2.1', '2.0.9'), isTrue);
      expect(UpdateInfo.isNewer('2.0.2', '2.0.2'), isFalse);
      expect(UpdateInfo.isNewer('2.0.1', '2.0.2'), isFalse);
      expect(UpdateInfo.isNewer('2.0.2+5', '2.0.2+4'), isTrue);
      expect(UpdateInfo.isNewer('2.0.2', '2.0.2+4'), isFalse);
    });
  });

  group('loopback server', () {
    late HttpServer server;
    late Directory dir;
    final payload = List<int>.generate(300000, (i) => i % 251);
    final payloadSha = crypto.sha256.convert(payload).toString();

    var busyHits = 0;

    setUp(() async {
      busyHits = 0;
      AutoUpdater.busyMinWait = 0;
      dir = Directory.systemTemp.createTempSync('tp_upd');
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        final r = req.response;
        switch (req.uri.path) {
          case '/api/v1/product/thaiprompt-pos/update/check':
            expect(req.uri.queryParameters['current_version'], '2.0.2');
            r.headers.contentType = ContentType('application', 'json'); // no charset, like the site
            r.add(utf8.encode(jsonEncode(offer(changelog: 'เครื่องพิมพ์ใบเสร็จ'))));
          case '/file':
            r.headers.contentType = ContentType('application', 'octet-stream');
            r.add(payload);
          case '/chunked':
            r.headers.contentType = ContentType('application', 'octet-stream');
            r.headers.chunkedTransferEncoding = true;
            r.add(payload.sublist(0, 1000));
            await r.flush();
            r.add(payload.sublist(1000));
          case '/short':
            r.headers.contentType = ContentType('application', 'octet-stream');
            r.add(payload.sublist(0, 1000));
          case '/redirect':
            r.statusCode = 302;
            r.headers.set(HttpHeaders.locationHeader, 'http://127.0.0.1:${server.port}/file');
          case '/html':
            r.headers.contentType = ContentType.html;
            r.write('<html>login</html>');
          case '/busy':
            r.statusCode = 503;
            r.headers.set(HttpHeaders.retryAfterHeader, '1');
          case '/busy-once':
            if (busyHits++ == 0) {
              r.statusCode = 503;
              r.headers.set(HttpHeaders.retryAfterHeader, '1');
            } else {
              r.headers.contentType = ContentType('application', 'octet-stream');
              r.add(payload);
            }
          default:
            r.statusCode = 404;
        }
        await r.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      dir.deleteSync(recursive: true);
    });

    Uri u(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');
    File target() => File('${dir.path}/update.bin');

    test('update/check decodes Thai JSON sent without a charset', () async {
      final up = AutoUpdater(slug: kUpdateSlugAndroid, checkBase: u('/'));
      final info = await up.checkForUpdate(currentVersion: '2.0.2');
      expect(info, isNotNull);
      expect(info!.hasUpdate, isTrue);
      expect(info.releaseNotes, 'เครื่องพิมพ์ใบเสร็จ');
    });

    test('unknown product → null (cannot check), never "up to date"', () async {
      final up = AutoUpdater(slug: 'nope', checkBase: u('/'));
      expect(await up.checkForUpdate(currentVersion: '2.0.2'), isNull);
    });

    test('verified download keeps the file', () async {
      final pct = <double>[];
      final f = await AutoUpdater.downloadVerified(u('/file'), target(),
          size: payload.length, sha256: payloadSha, onProgress: pct.add);
      expect(f.lengthSync(), payload.length);
      expect(pct.last, closeTo(100, 0.001));
      expect(File('${target().path}.part').existsSync(), isFalse);
    });

    test('chunked answer without Content-Length still verifies', () async {
      final f = await AutoUpdater.downloadVerified(u('/chunked'), target(), size: payload.length, sha256: payloadSha);
      expect(f.lengthSync(), payload.length);
    });

    test('503 "slots full" waits Retry-After and retries', () async {
      final waits = <int>[];
      final f = await AutoUpdater.downloadVerified(u('/busy-once'), target(),
          size: payload.length, sha256: payloadSha, onBusyWait: waits.add);
      expect(f.lengthSync(), payload.length);
      expect(waits, [1]);
    });

    Future<void> refused(String path, {int? size, String? sha}) async {
      await expectLater(
        AutoUpdater.downloadVerified(u(path), target(), size: size ?? payload.length, sha256: sha ?? payloadSha),
        throwsA(isA<UpdateException>()),
      );
      expect(target().existsSync(), isFalse, reason: path);
      expect(File('${target().path}.part').existsSync(), isFalse, reason: path);
    }

    test('wrong SHA-256, short body, wrong size, redirect, HTML, busy → refused and cleaned up', () async {
      await refused('/file', sha: 'b' * 64);
      await refused('/short', size: 1000 + 1);
      await refused('/file', size: payload.length - 1);
      await refused('/chunked', size: payload.length - 1);
      await refused('/redirect');
      await refused('/html');
      await refused('/busy');
      await refused('/missing');
    });
  });
}
