import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/web_share_item.dart';
import 'storage_service.dart';
import 'web_portal_html.dart';

typedef OnWebFileReceived = void Function(File file, String originalName, int sizeBytes);
typedef OnWebTextReceived = void Function(String text);

class WebShareService {
  final StorageService storageService;
  final String deviceName;
  final OnWebFileReceived? onFileReceived;
  final OnWebTextReceived? onTextReceived;

  HttpServer? _server;
  int _port = 5050;
  String _sessionToken = '';
  String _sessionPin = '';
  String _localIp = '';

  final Map<String, SharedFileItem> _sharedFiles = {};
  int _activeWebClients = 0;

  bool get isRunning => _server != null;
  int get port => _port;
  String get sessionToken => _sessionToken;
  String get sessionPin => _sessionPin;
  String get localIp => _localIp;
  List<SharedFileItem> get sharedFiles => _sharedFiles.values.toList();
  int get activeWebClients => _activeWebClients;

  WebShareService({
    required this.storageService,
    required this.deviceName,
    this.onFileReceived,
    this.onTextReceived,
  });

  /// Starts the embedded Web Share server with a secure ephemeral token and 4-digit PIN
  Future<void> start({
    required String localIp,
    List<SharedFileItem>? initialFiles,
    int preferredPort = 5050,
  }) async {
    if (isRunning) await stop();

    _localIp = localIp;
    _sharedFiles.clear();
    if (initialFiles != null) {
      for (final f in initialFiles) {
        _sharedFiles[f.id] = f;
      }
    }

    // Generate cryptographic token and friendly 4-digit PIN
    final rand = Random.secure();
    _sessionToken = List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
    _sessionPin = (rand.nextInt(9000) + 1000).toString();

    // Bind server with port fallback if 5050 is occupied
    int currentPort = preferredPort;
    while (_server == null && currentPort < preferredPort + 10) {
      try {
        _server = await HttpServer.bind(
          InternetAddress.anyIPv4,
          currentPort,
          shared: false,
        );
        _port = currentPort;
      } catch (_) {
        currentPort++;
      }
    }

    if (_server == null) {
      // Fallback: let OS assign any available port
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _port = _server!.port;
    }

    _server!.listen(_handleHttpRequest, onError: (err) {
      debugPrint('WebShareService server error: $err');
    });

    debugPrint('WebShareService running on http://$_localIp:$_port/?token=$_sessionToken (PIN: $_sessionPin)');
  }

  /// Stops the server and clears session secrets
  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _sharedFiles.clear();
    _activeWebClients = 0;
    debugPrint('WebShareService stopped');
  }

  /// Adds a file to the active sharing list
  void addSharedFile(SharedFileItem file) {
    _sharedFiles[file.id] = file;
  }

  /// Removes a file from the active sharing list
  void removeSharedFile(String id) {
    _sharedFiles.remove(id);
  }

  /// Full URL for the web portal with embedded token for 1-tap browser auth
  String get webPortalUrl {
    final ip = _localIp.isNotEmpty ? _localIp : '127.0.0.1';
    return 'http://$ip:$_port/?token=$_sessionToken';
  }

  /// Stripped URL without token (requires entering the 4-digit PIN)
  String get cleanWebUrl {
    final ip = _localIp.isNotEmpty ? _localIp : '127.0.0.1';
    return 'http://$ip:$_port';
  }

  /// Security validation: verifies request carries valid session token or PIN
  bool _isAuthorized(HttpRequest req) {
    // 1. Check Query parameter ?token=
    final queryToken = req.uri.queryParameters['token'];
    if (queryToken != null && queryToken == _sessionToken) return true;

    // 2. Check Header X-LocalDrop-Token
    final headerToken = req.headers.value('X-LocalDrop-Token');
    if (headerToken != null && headerToken == _sessionToken) return true;

    return false;
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    // Add CORS headers for local LAN web client operations
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'X-LocalDrop-Token, Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    try {
      // 1. Root / UI Portal Endpoint
      if (path == '/' || path == '/index.html') {
        final html = WebPortalHtml.build(
          deviceName: deviceName,
          pin: _sessionPin,
          token: _sessionToken,
        );
        request.response.headers.contentType = ContentType.html;
        request.response.write(html);
        await request.response.close();
        return;
      }

      // 2. Auth API Endpoint: Verifies PIN and returns token
      if (path == '/api/auth' && request.method == 'POST') {
        final bodyStr = await utf8.decoder.bind(request).join();
        try {
          final data = jsonDecode(bodyStr);
          final pin = data['pin']?.toString().trim();
          if (pin == _sessionPin) {
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'success': true, 'token': _sessionToken}));
          } else {
            request.response.statusCode = HttpStatus.forbidden;
            request.response.write(jsonEncode({'success': false, 'error': 'Invalid PIN'}));
          }
        } catch (_) {
          request.response.statusCode = HttpStatus.badRequest;
        }
        await request.response.close();
        return;
      }

      // All remaining API endpoints require security authorization
      if (!_isAuthorized(request)) {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Unauthorized: Valid PIN or token required'}));
        await request.response.close();
        return;
      }

      // 3. Status API: Returns available files and metadata
      if (path == '/api/status' && request.method == 'GET') {
        request.response.headers.contentType = ContentType.json;
        final payload = {
          'deviceName': deviceName,
          'files': _sharedFiles.values.map((f) => f.toJson()).toList(),
        };
        request.response.write(jsonEncode(payload));
        await request.response.close();
        return;
      }

      // 4. Download API: Streams requested file safely from disk
      if (path == '/api/download' && request.method == 'GET') {
        final fileId = request.uri.queryParameters['id'];
        final item = _sharedFiles[fileId];

        if (item == null) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('File not found in active share session');
          await request.response.close();
          return;
        }

        final file = File(item.path);
        if (!await file.exists()) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('File no longer exists on host disk');
          await request.response.close();
          return;
        }

        // Set attachment headers for browser auto-download
        final cleanFileName = p.basename(item.name).replaceAll('"', r'\"');
        request.response.headers.set(
          'Content-Disposition',
          'attachment; filename="$cleanFileName"',
        );
        request.response.headers.set('Content-Length', item.sizeBytes.toString());
        request.response.headers.set('Content-Type', item.mimeType);

        // Stream chunks directly from disk with flat memory usage
        await file.openRead().pipe(request.response);
        return;
      }

      // 5. Upload API: Receives files sent from web browser directly to Downloads/LocalDrop
      if (path == '/api/upload' && request.method == 'POST') {
        final rawName = request.uri.queryParameters['name'] ?? 'upload_${DateTime.now().millisecondsSinceEpoch}';
        // Strict path traversal defense: strip any directory structure
        final safeName = p.basename(rawName).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

        // Resolve non-colliding destination path inside LocalDrop folder
        final destPath = await storageService.getUniqueDestinationPath(safeName);
        final tempFile = await storageService.createTempFile('web_${DateTime.now().millisecondsSinceEpoch}');

        final sink = tempFile.openWrite();
        int totalBytes = 0;

        await for (final chunk in request) {
          totalBytes += chunk.length;
          sink.add(chunk);
        }
        await sink.flush();
        await sink.close();

        // Move temp file to finalized path
        final finalizedFile = await storageService.finalizeFile(tempFile, destPath);

        // Notify app
        onFileReceived?.call(finalizedFile, safeName, totalBytes);

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'success': true,
          'name': safeName,
          'bytesReceived': totalBytes,
        }));
        await request.response.close();
        return;
      }

      // 6. Note/Text Drop API: Receives text or link from web browser
      if (path == '/api/note' && request.method == 'POST') {
        final text = await utf8.decoder.bind(request).join();
        if (text.trim().isNotEmpty) {
          onTextReceived?.call(text.trim());
        }
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'success': true}));
        await request.response.close();
        return;
      }

      // Unknown endpoint
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not found');
      await request.response.close();
    } catch (e) {
      debugPrint('Error handling web request ($path): $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Server Error');
        await request.response.close();
      } catch (_) {}
    }
  }
}
