import 'dart:io';
import 'dart:math';

class HotspotHelper {
  /// Generates standard ZXing Wi-Fi QR configuration string
  /// Format: `WIFI:S:<SSID>;T:<WPA|WEP|nopass>;P:<PASSWORD>;;`
  static String formatWifiQrString({
    required String ssid,
    required String password,
    String security = 'WPA',
  }) {
    final cleanSsid = _escape(ssid);
    if (password.isEmpty) {
      return 'WIFI:S:$cleanSsid;T:nopass;;';
    }
    final cleanPass = _escape(password);
    return 'WIFI:S:$cleanSsid;T:$security;P:$cleanPass;;';
  }

  static String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:')
        .replaceAll('"', r'\"');
  }

  /// Generates a friendly unique Hotspot SSID
  static String generateDefaultSsid() {
    final rand = Random().nextInt(900) + 100;
    return 'LocalDrop-$rand';
  }

  /// Generates a simple secure 8-character hotspot passphrase
  static String generateDefaultPassword() {
    final rand = Random().nextInt(9000) + 1000;
    return 'drop$rand';
  }

  /// Discovers available non-loopback IPv4 network addresses, prioritizing AP/hotspot gateways
  static Future<List<String>> getAvailableIpAddresses() async {
    final ips = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip != '127.0.0.1' && ip != '0.0.0.0') {
            ips.add(ip);
          }
        }
      }
    } catch (_) {}

    // Sort to prioritize common hotspot/tether interfaces first (192.168.43.x, 192.168.49.x, 192.168.137.x, 172.20.10.x)
    ips.sort((a, b) {
      int score(String ip) {
        if (ip.startsWith('192.168.43.') || ip.startsWith('192.168.49.')) return 100;
        if (ip.startsWith('172.20.10.')) return 90;
        if (ip.startsWith('192.168.137.')) return 80;
        if (ip.startsWith('192.168.')) return 70;
        if (ip.startsWith('10.')) return 60;
        return 10;
      }

      return score(b).compareTo(score(a));
    });

    return ips;
  }
}
