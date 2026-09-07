import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _folderName = 'LocalDrop';
  final Directory? customBaseDirectory;

  StorageService({this.customBaseDirectory});

  /// Resolves the dedicated LocalDrop download directory
  Future<Directory> getDownloadDirectory() async {
    if (customBaseDirectory != null) {
      if (!await customBaseDirectory!.exists()) {
        await customBaseDirectory!.create(recursive: true);
      }
      return customBaseDirectory!;
    }

    Directory? baseDir;

    try {
      if (Platform.isAndroid) {
        baseDir = await getDownloadsDirectory();
        baseDir ??= await getExternalStorageDirectory();
      } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        baseDir = await getDownloadsDirectory();
      }
    } catch (_) {}

    try {
      baseDir ??= await getApplicationDocumentsDirectory();
    } catch (_) {
      baseDir ??= Directory.systemTemp;
    }

    final localDropDir = Directory(p.join(baseDir.path, _folderName));
    if (!await localDropDir.exists()) {
      await localDropDir.create(recursive: true);
    }
    return localDropDir;
  }

  /// Generates a non-colliding destination file path
  Future<String> getUniqueDestinationPath(
    String originalFileName, {
    Directory? customDirectory,
  }) async {
    final saveDir = customDirectory ?? await getDownloadDirectory();
    final sanitizedName = p
        .basename(originalFileName)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

    String candidatePath = p.join(saveDir.path, sanitizedName);
    if (!await File(candidatePath).exists()) {
      return candidatePath;
    }

    final extension = p.extension(sanitizedName);
    final baseName = p.basenameWithoutExtension(sanitizedName);

    int counter = 1;
    while (await File(
      p.join(saveDir.path, '$baseName ($counter)$extension'),
    ).exists()) {
      counter++;
    }

    return p.join(saveDir.path, '$baseName ($counter)$extension');
  }

  /// Creates a temporary file path for in-progress chunk streaming
  Future<File> createTempFile(String transferId) async {
    final saveDir = await getDownloadDirectory();
    final tempPath = p.join(saveDir.path, '.localdrop_tmp_$transferId');
    final file = File(tempPath);
    if (await file.exists()) {
      await file.delete();
    }
    return file.create();
  }

  /// Finalizes temporary file by moving it to the destination path
  Future<File> finalizeFile(File tempFile, String destinationPath) async {
    final destFile = File(destinationPath);
    if (await destFile.exists()) {
      await destFile.delete();
    }
    return tempFile.rename(destinationPath);
  }

  /// Cleans up temporary file if transfer fails or is cancelled
  Future<void> cleanupTempFile(String transferId) async {
    try {
      final saveDir = await getDownloadDirectory();
      final tempPath = p.join(saveDir.path, '.localdrop_tmp_$transferId');
      final file = File(tempPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
