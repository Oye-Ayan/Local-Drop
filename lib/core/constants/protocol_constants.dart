class ProtocolConstants {
  /// Default service type for Bonjour / mDNS network service discovery
  static const String serviceType = '_localdrop._tcp';

  /// Default TCP port for file transfer and direct socket messaging
  static const int defaultTcpPort = 53317;

  /// UDP port for broadcast beacon discovery fallback
  static const int defaultUdpPort = 53318;

  /// Protocol version
  static const int protocolVersion = 1;

  /// Chunk size for streaming file transfers (512KB for ultra high-speed LAN/Wi-Fi transfers)
  static const int chunkSize = 512 * 1024;

  /// Timeout for incoming transfer acceptance before auto-rejecting (seconds)
  static const int transferPromptTimeoutSeconds = 30;

  /// Device discovery TTL in seconds (remove peer if not heard from)
  static const int peerTtlSeconds = 8;

  /// Broadcast beacon interval in seconds
  static const int beaconIntervalSeconds = 3;

  // Protocol Message Types (OpCodes)
  static const int msgHandshakeInit = 0x01;
  static const int msgHandshakeAck = 0x02;
  static const int msgTransferRequest = 0x03;
  static const int msgTransferAccept = 0x04;
  static const int msgTransferReject = 0x05;
  static const int msgFileChunk = 0x06;
  static const int msgTransferComplete = 0x07;
  static const int msgClipboardPush = 0x08;
  static const int msgError = 0x09;
  static const int msgPing = 0x0A;
  static const int msgPong = 0x0B;

  // Error Codes
  static const int errDeclined = 1001;
  static const int errTimeout = 1002;
  static const int errChecksumMismatch = 1003;
  static const int errCancelled = 1004;
  static const int errDiskFull = 1005;
  static const int errUnknown = 1099;
}
