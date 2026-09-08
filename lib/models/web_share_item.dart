import 'package:path/path.dart' as p;

/// Represents an individual file shared over the local Web Portal
class SharedFileItem {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String mimeType;

  const SharedFileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.mimeType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
      };

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String guessMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.pdf':
        return 'application/pdf';
      case '.mp4':
        return 'video/mp4';
      case '.mkv':
        return 'video/x-matroska';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.zip':
        return 'application/zip';
      case '.tar':
      case '.gz':
        return 'application/gzip';
      case '.txt':
      case '.md':
      case '.json':
        return 'text/plain; charset=utf-8';
      default:
        return 'application/octet-stream';
    }
  }
}
