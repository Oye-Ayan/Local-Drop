import 'dart:convert';
import 'package:flutter/material.dart';
import 'transfer_item.dart';

class HistoryItem {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final String filePath;
  final TransferDirection direction;
  final String peerName;
  final String peerIp;
  final DateTime timestamp;
  final bool isPinned;
  final String? sha256;

  const HistoryItem({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.filePath,
    required this.direction,
    required this.peerName,
    required this.peerIp,
    required this.timestamp,
    this.isPinned = false,
    this.sha256,
  });

  /// Factory to create HistoryItem from a completed TransferItem
  factory HistoryItem.fromTransferItem(TransferItem item, {bool isPinned = false}) {
    return HistoryItem(
      id: item.id,
      fileName: item.fileName,
      fileSizeBytes: item.fileSizeBytes,
      filePath: item.filePath,
      direction: item.direction,
      peerName: item.peerName,
      peerIp: item.peerIp,
      timestamp: item.endTime ?? DateTime.now(),
      isPinned: isPinned,
      sha256: item.sha256Checksum,
    );
  }

  HistoryItem copyWith({
    String? id,
    String? fileName,
    int? fileSizeBytes,
    String? filePath,
    TransferDirection? direction,
    String? peerName,
    String? peerIp,
    DateTime? timestamp,
    bool? isPinned,
    String? sha256,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      filePath: filePath ?? this.filePath,
      direction: direction ?? this.direction,
      peerName: peerName ?? this.peerName,
      peerIp: peerIp ?? this.peerIp,
      timestamp: timestamp ?? this.timestamp,
      isPinned: isPinned ?? this.isPinned,
      sha256: sha256 ?? this.sha256,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'filePath': filePath,
      'direction': direction.name,
      'peerName': peerName,
      'peerIp': peerIp,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': isPinned,
      'sha256': sha256,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      filePath: json['filePath'] as String? ?? '',
      direction: json['direction'] == 'incoming'
          ? TransferDirection.incoming
          : TransferDirection.outgoing,
      peerName: json['peerName'] as String? ?? 'Nearby Device',
      peerIp: json['peerIp'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isPinned: json['isPinned'] as bool? ?? false,
      sha256: json['sha256'] as String?,
    );
  }

  String serialize() => jsonEncode(toJson());

  factory HistoryItem.deserialize(String source) =>
      HistoryItem.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Checks if this item is older than the retention threshold
  bool isExpired({int retentionDays = 7}) {
    if (isPinned) return false; // Pinned items never expire
    final diff = DateTime.now().difference(timestamp);
    return diff.inDays >= retentionDays;
  }

  IconData get icon {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
        return Icons.image_rounded;
      case 'mp4':
      case 'mkv':
      case 'webm':
      case 'mov':
      case 'avi':
        return Icons.videocam_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return Icons.audiotrack_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;
      case 'txt':
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
