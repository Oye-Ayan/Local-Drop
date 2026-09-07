import 'dart:math';

class Formatters {
  /// Formats byte counts into human-readable strings (e.g. 1.2 MB, 450 KB, 1.8 GB)
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor().clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, i);
    if (i == 0) return '$bytes B';
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Formats transfer speed in bytes per second to MB/s or KB/s
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 KB/s';
    if (bytesPerSecond < 1024 * 1024) {
      final kb = bytesPerSecond / 1024;
      return '${kb.toStringAsFixed(1)} KB/s';
    }
    final mb = bytesPerSecond / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB/s';
  }

  /// Formats remaining duration into mm:ss or hh:mm:ss
  static String formatEta(Duration remaining) {
    if (remaining.isNegative || remaining.inSeconds <= 0) {
      return '0s';
    }
    if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    }
    if (remaining.inMinutes > 0) {
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds.remainder(60);
      return '${minutes}m ${seconds}s';
    }
    return '${remaining.inSeconds}s';
  }
}
