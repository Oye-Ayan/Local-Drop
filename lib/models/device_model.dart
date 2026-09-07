import 'package:flutter/material.dart';

enum DeviceType {
  phone,
  tablet,
  desktop,
  unknown;

  static DeviceType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'phone':
      case 'mobile':
      case 'android':
        return DeviceType.phone;
      case 'tablet':
      case 'ipad':
        return DeviceType.tablet;
      case 'desktop':
      case 'linux':
      case 'windows':
      case 'macos':
        return DeviceType.desktop;
      default:
        return DeviceType.unknown;
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.phone:
        return Icons.phone_android_rounded;
      case DeviceType.tablet:
        return Icons.tablet_android_rounded;
      case DeviceType.desktop:
        return Icons.computer_rounded;
      case DeviceType.unknown:
        return Icons.devices_other_rounded;
    }
  }
}

class DeviceModel {
  final String id;
  final String name;
  final String ip;
  final int port;
  final DeviceType deviceType;
  final String osName;
  final DateTime lastSeen;
  final bool isSelf;
  final String discoverySource;

  DeviceModel({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.deviceType,
    required this.osName,
    DateTime? lastSeen,
    this.isSelf = false,
    this.discoverySource = 'mdns',
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Device',
      ip: json['ip'] as String? ?? '',
      port: (json['port'] as num?)?.toInt() ?? 53317,
      deviceType: DeviceType.fromString(json['deviceType'] as String?),
      osName: json['osName'] as String? ?? 'Unknown OS',
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSelf: json['isSelf'] as bool? ?? false,
      discoverySource: json['discoverySource'] as String? ?? 'udp',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
      'deviceType': deviceType.name,
      'osName': osName,
      'lastSeen': lastSeen.toIso8601String(),
      'isSelf': isSelf,
      'discoverySource': discoverySource,
    };
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    DeviceType? deviceType,
    String? osName,
    DateTime? lastSeen,
    bool? isSelf,
    String? discoverySource,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      deviceType: deviceType ?? this.deviceType,
      osName: osName ?? this.osName,
      lastSeen: lastSeen ?? this.lastSeen,
      isSelf: isSelf ?? this.isSelf,
      discoverySource: discoverySource ?? this.discoverySource,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DeviceModel(id: $id, name: $name, ip: $ip, port: $port, type: ${deviceType.name}, os: $osName)';
}
