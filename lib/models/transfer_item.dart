import '../core/utils/formatters.dart';

enum TransferDirection {
  incoming,
  outgoing;

  bool get isIncoming => this == TransferDirection.incoming;
  bool get isOutgoing => this == TransferDirection.outgoing;
}

enum TransferStatus {
  pending,
  inProgress,
  completed,
  rejected,
  failed,
  cancelled;

  bool get isDone =>
      this == TransferStatus.completed ||
      this == TransferStatus.rejected ||
      this == TransferStatus.failed ||
      this == TransferStatus.cancelled;

  bool get isSuccess => this == TransferStatus.completed;
}

class TransferItem {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final int bytesTransferred;
  final String filePath;
  final TransferDirection direction;
  final String peerId;
  final String peerName;
  final String peerIp;
  final TransferStatus status;
  final double speedBytesPerSec;
  final DateTime startTime;
  final DateTime? endTime;
  final String? sha256Checksum;
  final bool checksumVerified;
  final String? errorMessage;

  TransferItem({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    this.bytesTransferred = 0,
    required this.filePath,
    required this.direction,
    required this.peerId,
    required this.peerName,
    required this.peerIp,
    this.status = TransferStatus.pending,
    this.speedBytesPerSec = 0,
    DateTime? startTime,
    this.endTime,
    this.sha256Checksum,
    this.checksumVerified = false,
    this.errorMessage,
  }) : startTime = startTime ?? DateTime.now();

  double get progress => fileSizeBytes > 0
      ? (bytesTransferred / fileSizeBytes).clamp(0.0, 1.0)
      : 0.0;

  int get percentage => (progress * 100).toInt();

  String get formattedSize => Formatters.formatBytes(fileSizeBytes);
  String get formattedTransferred => Formatters.formatBytes(bytesTransferred);
  String get formattedSpeed => Formatters.formatSpeed(speedBytesPerSec);

  Duration? get eta {
    if (status.isDone ||
        speedBytesPerSec <= 0 ||
        fileSizeBytes <= bytesTransferred) {
      return null;
    }
    final remainingBytes = fileSizeBytes - bytesTransferred;
    final seconds = remainingBytes / speedBytesPerSec;
    return Duration(seconds: seconds.ceil());
  }

  TransferItem copyWith({
    String? id,
    String? fileName,
    int? fileSizeBytes,
    int? bytesTransferred,
    String? filePath,
    TransferDirection? direction,
    String? peerId,
    String? peerName,
    String? peerIp,
    TransferStatus? status,
    double? speedBytesPerSec,
    DateTime? startTime,
    DateTime? endTime,
    String? sha256Checksum,
    bool? checksumVerified,
    String? errorMessage,
  }) {
    return TransferItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      filePath: filePath ?? this.filePath,
      direction: direction ?? this.direction,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerIp: peerIp ?? this.peerIp,
      status: status ?? this.status,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sha256Checksum: sha256Checksum ?? this.sha256Checksum,
      checksumVerified: checksumVerified ?? this.checksumVerified,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'bytesTransferred': bytesTransferred,
      'filePath': filePath,
      'direction': direction.name,
      'peerId': peerId,
      'peerName': peerName,
      'peerIp': peerIp,
      'status': status.name,
      'speedBytesPerSec': speedBytesPerSec,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'sha256Checksum': sha256Checksum,
      'checksumVerified': checksumVerified,
      'errorMessage': errorMessage,
    };
  }

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      bytesTransferred: (json['bytesTransferred'] as num?)?.toInt() ?? 0,
      filePath: json['filePath'] as String? ?? '',
      direction: TransferDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => TransferDirection.incoming,
      ),
      peerId: json['peerId'] as String? ?? '',
      peerName: json['peerName'] as String? ?? '',
      peerIp: json['peerIp'] as String? ?? '',
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.pending,
      ),
      speedBytesPerSec: (json['speedBytesPerSec'] as num?)?.toDouble() ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      sha256Checksum: json['sha256Checksum'] as String?,
      checksumVerified: json['checksumVerified'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
