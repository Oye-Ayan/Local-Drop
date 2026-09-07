import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/protocol_constants.dart';
import '../models/device_model.dart';

class DiscoveryService {
  final DeviceModel localDevice;
  final Function(List<DeviceModel> peers)? onPeersChanged;

  final Map<String, DeviceModel> _peers = {};
  final StreamController<List<DeviceModel>> _peersStreamController =
      StreamController<List<DeviceModel>>.broadcast();

  // mDNS (Bonsoir)
  BonsoirBroadcast? _bonsoirBroadcast;
  BonsoirDiscovery? _bonsoirDiscovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _bonsoirSubscription;

  // UDP Beacon
  RawDatagramSocket? _udpSocket;
  Timer? _udpBroadcastTimer;

  // Peer TTL Pruning
  Timer? _pruningTimer;

  bool _isRunning = false;

  DiscoveryService({required this.localDevice, this.onPeersChanged});

  Stream<List<DeviceModel>> get peersStream => _peersStreamController.stream;
  List<DeviceModel> get currentPeers => _peers.values.toList();
  bool get isRunning => _isRunning;

  /// Starts dual-mode discovery: mDNS + UDP broadcast beacon
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Start TTL pruner
    _pruningTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pruneExpiredPeers(),
    );

    // 1. Initialize UDP Beacon
    await _startUdpBeacon();

    // 2. Initialize mDNS via Bonsoir
    await _startMdns();

    debugPrint(
      'DiscoveryService started for device: ${localDevice.name} (${localDevice.id})',
    );
  }

  /// Stops all discovery services
  Future<void> stop() async {
    _isRunning = false;
    _pruningTimer?.cancel();
    _udpBroadcastTimer?.cancel();

    try {
      _udpSocket?.close();
    } catch (_) {}
    _udpSocket = null;

    try {
      await _bonsoirSubscription?.cancel();
      _bonsoirSubscription = null;
      await _bonsoirDiscovery?.stop();
      _bonsoirDiscovery = null;
      await _bonsoirBroadcast?.stop();
      _bonsoirBroadcast = null;
    } catch (_) {}

    _peers.clear();
    _notifyPeersChanged();
    debugPrint('DiscoveryService stopped');
  }

  /// Updates a peer or registers a newly discovered peer
  void _updatePeer(DeviceModel peer) {
    if (peer.id == localDevice.id || peer.isSelf) {
      return; // Ignore self
    }

    final existing = _peers[peer.id];
    final updated = peer.copyWith(
      lastSeen: DateTime.now(),
      ip: (peer.ip.isNotEmpty && peer.ip != '127.0.0.1')
          ? peer.ip
          : (existing?.ip ?? peer.ip),
    );

    _peers[peer.id] = updated;
    _notifyPeersChanged();
  }

  /// Removes peers that haven't been seen within peerTtlSeconds
  void _pruneExpiredPeers() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _peers.entries) {
      if (now.difference(entry.value.lastSeen).inSeconds >
          ProtocolConstants.peerTtlSeconds) {
        expiredKeys.add(entry.key);
      }
    }

    if (expiredKeys.isNotEmpty) {
      for (final key in expiredKeys) {
        _peers.remove(key);
      }
      _notifyPeersChanged();
    }
  }

  void _notifyPeersChanged() {
    final list = _peers.values.toList();
    _peersStreamController.add(list);
    onPeersChanged?.call(list);
  }

  // ==========================================
  // UDP BROADCAST BEACON (DUAL-MODE FALLBACK)
  // ==========================================

  Future<void> _startUdpBeacon() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        ProtocolConstants.defaultUdpPort,
        reuseAddress: true,
        reusePort: true,
      );
      _udpSocket?.broadcastEnabled = true;

      _udpSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket?.receive();
          if (datagram != null) {
            _handleUdpDatagram(datagram);
          }
        }
      });

      // Broadcast beacon periodically
      _sendUdpBeacon();
      _udpBroadcastTimer = Timer.periodic(
        const Duration(seconds: ProtocolConstants.beaconIntervalSeconds),
        (_) => _sendUdpBeacon(),
      );
    } catch (e) {
      debugPrint('UDP beacon init warning: $e');
    }
  }

  void _sendUdpBeacon() {
    if (!_isRunning || _udpSocket == null) return;
    try {
      final payload = jsonEncode({
        'id': localDevice.id,
        'name': localDevice.name,
        'ip': localDevice.ip,
        'port': localDevice.port,
        'deviceType': localDevice.deviceType.name,
        'osName': localDevice.osName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      final bytes = utf8.encode(payload);

      // Send to local broadcast address
      _udpSocket?.send(
        bytes,
        InternetAddress('255.255.255.255'),
        ProtocolConstants.defaultUdpPort,
      );

      // Also send to subnet broadcast if local IP is known
      if (localDevice.ip.isNotEmpty && localDevice.ip.contains('.')) {
        final parts = localDevice.ip.split('.');
        if (parts.length == 4) {
          final subnetBroadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
          _udpSocket?.send(
            bytes,
            InternetAddress(subnetBroadcast),
            ProtocolConstants.defaultUdpPort,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending UDP beacon: $e');
    }
  }

  void _handleUdpDatagram(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final json = jsonDecode(text) as Map<String, dynamic>;

      final peerId = json['id'] as String? ?? '';
      if (peerId.isEmpty || peerId == localDevice.id) return;

      // Prefer sender IP if reported IP is empty or loopback
      String peerIp = json['ip'] as String? ?? '';
      if (peerIp.isEmpty || peerIp == '127.0.0.1' || peerIp == '0.0.0.0') {
        peerIp = datagram.address.address;
      }

      final peer = DeviceModel(
        id: peerId,
        name: json['name'] as String? ?? 'Nearby Device',
        ip: peerIp,
        port:
            (json['port'] as num?)?.toInt() ?? ProtocolConstants.defaultTcpPort,
        deviceType: DeviceType.fromString(json['deviceType'] as String?),
        osName: json['osName'] as String? ?? '',
        lastSeen: DateTime.now(),
        discoverySource: 'udp',
      );

      _updatePeer(peer);
    } catch (_) {
      // Ignore malformed packets
    }
  }

  // ==========================================
  // mDNS (BONSOIR) DISCOVERY & BROADCAST
  // ==========================================

  Future<void> _startMdns() async {
    try {
      // 1. Broadcast service
      final broadcastService = BonsoirService(
        name: 'localdrop-${localDevice.id}',
        type: ProtocolConstants.serviceType,
        port: localDevice.port,
        attributes: {
          'id': localDevice.id,
          'name': localDevice.name,
          'deviceType': localDevice.deviceType.name,
          'osName': localDevice.osName,
        },
      );

      _bonsoirBroadcast = BonsoirBroadcast(service: broadcastService);
      await _bonsoirBroadcast!.initialize();
      await _bonsoirBroadcast!.start();

      // 2. Discovery service
      _bonsoirDiscovery = BonsoirDiscovery(type: ProtocolConstants.serviceType);
      await _bonsoirDiscovery!.initialize();

      _bonsoirSubscription = _bonsoirDiscovery!.eventStream?.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          _bonsoirDiscovery?.serviceResolver.resolveService(event.service);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          final service = event.service;
          final attrs = service.attributes;
          final peerId =
              attrs['id'] ?? service.name.replaceFirst('localdrop-', '');
          if (peerId == localDevice.id) return;

          final host = service.host;
          final port = service.port;
          final name = attrs['name'] ?? service.name;
          final typeStr = attrs['deviceType'];
          final os = attrs['osName'] ?? '';

          final peer = DeviceModel(
            id: peerId,
            name: name,
            ip: host ?? '',
            port: port,
            deviceType: DeviceType.fromString(typeStr),
            osName: os,
            lastSeen: DateTime.now(),
            discoverySource: 'mdns',
          );

          _updatePeer(peer);
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          final service = event.service;
          final peerId =
              service.attributes['id'] ??
              service.name.replaceFirst('localdrop-', '');
          _peers.remove(peerId);
          _notifyPeersChanged();
        }
      });

      await _bonsoirDiscovery!.start();
    } catch (e) {
      debugPrint('mDNS Bonsoir warning (UDP fallback active): $e');
    }
  }

  void dispose() {
    stop();
    _peersStreamController.close();
  }
}
