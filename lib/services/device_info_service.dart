import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/protocol_constants.dart';
import '../models/device_model.dart';

class DeviceInfoService {
  static const String _keyDeviceId = 'localdrop_device_id';
  static const String _keyCustomName = 'localdrop_custom_device_name';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Returns a persistent unique identifier for this device
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      id = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  /// Sets a custom user-chosen device name
  Future<void> setCustomDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomName, name.trim());
  }

  /// Retrieves the default or user-customized device name
  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final customName = prefs.getString(_keyCustomName);
    if (customName != null && customName.trim().isNotEmpty) {
      return customName.trim();
    }

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        final model = info.model;
        final brand = info.brand;
        if (model.toLowerCase().startsWith(brand.toLowerCase())) {
          return model;
        }
        return '$brand $model';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return info.prettyName.isNotEmpty
            ? info.prettyName
            : Platform.localHostname;
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return info.computerName.isNotEmpty
            ? info.computerName
            : Platform.localHostname;
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return info.computerName.isNotEmpty
            ? info.computerName
            : Platform.localHostname;
      }
    } catch (_) {
      // Fallback
    }
    return Platform.localHostname.isNotEmpty
        ? Platform.localHostname
        : 'LocalDrop Device';
  }

  /// Determines the local device type
  DeviceType getDeviceType() {
    if (Platform.isAndroid || Platform.isIOS) {
      return DeviceType.phone;
    } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      return DeviceType.desktop;
    }
    return DeviceType.unknown;
  }

  /// Returns the OS name string
  String getOsName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    return Platform.operatingSystem;
  }

  /// Resolves the current Wi-Fi/LAN IPv4 address
  Future<String> getLocalIpAddress() async {
    try {
      // Try network_info_plus first
      final wifiIp = await _networkInfo.getWifiIP();
      if (wifiIp != null &&
          wifiIp.isNotEmpty &&
          wifiIp != '0.0.0.0' &&
          wifiIp != '127.0.0.1') {
        return wifiIp;
      }
    } catch (_) {}

    try {
      // Search active network interfaces for a valid private IPv4 address
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
        includeLoopback: false,
      );

      // Prioritize Wi-Fi and Ethernet interfaces
      for (final interface in interfaces) {
        final lowerName = interface.name.toLowerCase();
        final isPreferred =
            lowerName.startsWith('wl') ||
            lowerName.startsWith('wi') ||
            lowerName.startsWith('en') ||
            lowerName.startsWith('eth');

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && isPrivateIpv4(addr.address)) {
            if (isPreferred) {
              return addr.address;
            }
          }
        }
      }

      // If no preferred interface matched, take any private IPv4
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && isPrivateIpv4(addr.address)) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return '127.0.0.1';
  }

  static bool isPrivateIpv4(String ip) {
    if (ip.startsWith('192.168.') || ip.startsWith('10.')) return true;
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final second = int.tryParse(parts[1]) ?? 0;
        if (second >= 16 && second <= 31) return true;
      }
    }
    return false;
  }

  /// Builds a complete DeviceModel for the local device
  Future<DeviceModel> getLocalDevice({
    int port = ProtocolConstants.defaultTcpPort,
  }) async {
    final id = await getDeviceId();
    final name = await getDeviceName();
    final ip = await getLocalIpAddress();
    final type = getDeviceType();
    final os = getOsName();

    return DeviceModel(
      id: id,
      name: name,
      ip: ip,
      port: port,
      deviceType: type,
      osName: os,
      isSelf: true,
      lastSeen: DateTime.now(),
    );
  }
}
