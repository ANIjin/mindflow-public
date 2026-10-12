import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// Personal vault sync server (no user accounts).
///
/// Vaults are keyed by a passphrase you choose. Put the same passphrase on
/// your laptop and phone to sync. Different passphrases = different vaults.
///
/// Run: `dart run tools/sync_server/bin/server.dart`
Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8787;
  final dataDir = Platform.environment['MINDFLOW_SYNC_DATA'] ??
      '${Directory.current.path}/.mindflow_sync_data';
  Directory('$dataDir/vaults').createSync(recursive: true);
  Directory('$dataDir/shares').createSync(recursive: true);

  String vaultId(Request req) {
    final header = req.headers['x-vault-id'];
    if (header != null && header.isNotEmpty) return header;
    final auth = req.headers['authorization'] ?? '';
    if (auth.toLowerCase().startsWith('bearer ')) {
      final pass = auth.substring(7).trim();
      return sha256.convert(utf8.encode('mindflow-vault::$pass')).toString();
    }
    return '';
  }

  bool authed(Request req) {
    final auth = req.headers['authorization'] ?? '';
    return auth.toLowerCase().startsWith('bearer ') &&
        auth.substring(7).trim().isNotEmpty;
  }

  final app = Router();
  app.get('/health', (Request req) => Response.ok('ok'));

  app.put('/v1/vault', (Request req) async {
    if (!authed(req)) return _err(401, 'missing passphrase');
    final id = vaultId(req);
    if (id.isEmpty) return _err(401, 'missing vault id');
    final body = await req.readAsString();
    await File('$dataDir/vaults/$id.json').writeAsString(body);
    return _json({'ok': true});
  });

  app.get('/v1/vault', (Request req) async {
    if (!authed(req)) return _err(401, 'missing passphrase');
    final id = vaultId(req);
    final f = File('$dataDir/vaults/$id.json');
    if (!f.existsSync()) return _err(404, 'no vault yet — sync once from a device');
    return Response.ok(f.readAsStringSync(),
        headers: {'Content-Type': 'application/json'});
  });

  app.post('/v1/shares', (Request req) async {
    if (!authed(req)) return _err(401, 'missing passphrase');
    final body = jsonDecode(await req.readAsString()) as Map;
    final code = _shareCode();
    final pack = {
      'code': code,
      'title': body['title'] ?? 'Shared',
      'nodes': body['nodes'] ?? [],
      'createdAt': DateTime.now().toIso8601String(),
    };
    await File('$dataDir/shares/$code.json').writeAsString(jsonEncode(pack));
    return _json(pack);
  });

  app.get('/v1/shares/<code>', (Request req, String code) async {
    // Share codes are redeemable with any authenticated device (friend sync
    // server or your own). They never grant access to a full vault.
    if (!authed(req)) return _err(401, 'missing passphrase');
    final f = File('$dataDir/shares/${code.toUpperCase()}.json');
    if (!f.existsSync()) return _err(404, 'share not found');
    return Response.ok(f.readAsStringSync(),
        headers: {'Content-Type': 'application/json'});
  });

  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(app.call);
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln(
      'MindFlow sync on http://${server.address.host}:${server.port}');
  stdout.writeln('Data: $dataDir');
  stdout.writeln(
      'Use the same sync passphrase on each of your devices to share one vault.');
}

Response _json(Object body, {int status = 200}) => Response(status,
    body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

Response _err(int status, String message) =>
    _json({'error': message}, status: status);

String _shareCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(8, (_) => alphabet[r.nextInt(alphabet.length)]).join();
}
