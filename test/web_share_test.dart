import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:localdrop/core/utils/hotspot_helper.dart';
import 'package:localdrop/models/web_share_item.dart';
import 'package:localdrop/services/storage_service.dart';
import 'package:localdrop/services/web_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HotspotHelper Tests', () {
    test('Format Wi-Fi QR string with WPA security', () {
      final qr = HotspotHelper.formatWifiQrString(
        ssid: 'MyHotspot',
        password: 'secretPassword123',
      );
      expect(qr, 'WIFI:S:MyHotspot;T:WPA;P:secretPassword123;;');
    });

    test('Format Wi-Fi QR string with special characters escaped', () {
      final qr = HotspotHelper.formatWifiQrString(
        ssid: r'My;Net,Work:Name\Test"',
        password: r'Pass;Word,123:\Test"',
      );
      expect(
        qr,
        r'WIFI:S:My\;Net\,Work\:Name\\Test\";T:WPA;P:Pass\;Word\,123\:\\Test\";;',
      );
    });

    test('Generates non-empty default SSID and Passwords', () {
      final ssid = HotspotHelper.generateDefaultSsid();
      final pass = HotspotHelper.generateDefaultPassword();
      expect(ssid.startsWith('LocalDrop-'), isTrue);
      expect(pass.startsWith('drop'), isTrue);
    });
  });

  group('WebShareService End-to-End Security & Transfer Tests', () {
    late Directory tempDir;
    late StorageService storageService;
    late WebShareService webShareService;
    final List<String> receivedFiles = [];
    final List<String> receivedNotes = [];

    setUp(() async {
      HttpOverrides.global = null;
      tempDir = await Directory.systemTemp.createTemp('localdrop_web_test_');
      storageService = StorageService(customBaseDirectory: tempDir);

      webShareService = WebShareService(
        storageService: storageService,
        deviceName: 'TestHostDevice',
        onFileReceived: (file, name, size) {
          receivedFiles.add(name);
        },
        onTextReceived: (text) {
          receivedNotes.add(text);
        },
      );
    });

    tearDown(() async {
      await webShareService.stop();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Full Web Share lifecycle: Auth gate, secure downloads, and reverse uploads', () async {
      // 1. Create a dummy test file to share
      final testFile = File('${tempDir.path}/secret_doc.txt');
      await testFile.writeAsString('LocalDrop 100% Offline Zero-Install Payload');

      final sharedItem = SharedFileItem(
        id: 'doc-1',
        name: 'secret_doc.txt',
        path: testFile.path,
        sizeBytes: await testFile.length(),
        mimeType: 'text/plain',
      );

      // 2. Start Web Share Service on 127.0.0.1
      await webShareService.start(
        localIp: '127.0.0.1',
        initialFiles: [sharedItem],
        preferredPort: 54321,
      );

      expect(webShareService.isRunning, isTrue);
      final port = webShareService.port;
      final token = webShareService.sessionToken;
      final pin = webShareService.sessionPin;

      expect(token.length, 16);
      expect(pin.length, 4);

      final client = HttpClient();

      // 3. Test Security Constraint: Accessing API without token must return 403 Forbidden
      final unauthReq = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/status'));
      final unauthRes = await unauthReq.close();
      expect(unauthRes.statusCode, HttpStatus.forbidden);

      // 4. Test PIN Authentication: Invalid PIN must return 403 Forbidden
      final badAuthReq = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/auth'));
      badAuthReq.headers.contentType = ContentType.json;
      badAuthReq.write(jsonEncode({'pin': '99999'}));
      final badAuthRes = await badAuthReq.close();
      expect(badAuthRes.statusCode, HttpStatus.forbidden);

      // 5. Test PIN Authentication: Correct PIN returns session token
      final goodAuthReq = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/auth'));
      goodAuthReq.headers.contentType = ContentType.json;
      goodAuthReq.write(jsonEncode({'pin': pin}));
      final goodAuthRes = await goodAuthReq.close();
      expect(goodAuthRes.statusCode, HttpStatus.ok);
      final goodAuthBody = jsonDecode(await utf8.decoder.bind(goodAuthRes).join());
      expect(goodAuthBody['success'], isTrue);
      expect(goodAuthBody['token'], token);

      // 6. Test Authorized Status API: Returns shared files list
      final statusReq = await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/status?token=$token'));
      final statusRes = await statusReq.close();
      expect(statusRes.statusCode, HttpStatus.ok);
      final statusBody = jsonDecode(await utf8.decoder.bind(statusRes).join());
      expect(statusBody['deviceName'], 'TestHostDevice');
      expect(statusBody['files'].length, 1);
      expect(statusBody['files'][0]['name'], 'secret_doc.txt');

      // 7. Test File Download: Download file with token
      final downloadReq = await client.getUrl(
        Uri.parse('http://127.0.0.1:$port/api/download?id=doc-1&token=$token'),
      );
      final downloadRes = await downloadReq.close();
      expect(downloadRes.statusCode, HttpStatus.ok);
      final downloadedContent = await utf8.decoder.bind(downloadRes).join();
      expect(downloadedContent, 'LocalDrop 100% Offline Zero-Install Payload');

      // 8. Test Reverse Upload from Web Browser to Host
      final uploadContent = 'File sent from Safari/Chrome without installing the app!';
      final uploadReq = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port/api/upload?name=from_browser.txt&token=$token'),
      );
      uploadReq.headers.set('X-LocalDrop-Token', token);
      uploadReq.write(uploadContent);
      final uploadRes = await uploadReq.close();
      expect(uploadRes.statusCode, HttpStatus.ok);
      expect(receivedFiles.contains('from_browser.txt'), isTrue);

      // Verify the uploaded file exists on disk in destination directory
      final savedFile = File('${tempDir.path}/from_browser.txt');
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsString(), uploadContent);

      // 9. Test Note/Text Drop
      final noteReq = await client.postUrl(Uri.parse('http://127.0.0.1:$port/api/note?token=$token'));
      noteReq.headers.set('X-LocalDrop-Token', token);
      noteReq.write('https://github.com/LocalDrop');
      final noteRes = await noteReq.close();
      expect(noteRes.statusCode, HttpStatus.ok);
      expect(receivedNotes.contains('https://github.com/LocalDrop'), isTrue);

      client.close();
    });
  });
}
