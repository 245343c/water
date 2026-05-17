import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies product photos into app documents so they survive restarts.
class ProductImageService {
  static const _uuid = Uuid();

  static Future<String?> persistFromFile(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final dir = await getApplicationDocumentsDirectory();
    final productsDir = Directory(p.join(dir.path, 'product_images'));
    if (!await productsDir.exists()) {
      await productsDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final destPath = p.join(productsDir.path, '${_uuid.v4()}$safeExt');
    await source.copy(destPath);
    return destPath;
  }

  static File? fileForPath(String? localPath) {
    if (localPath == null || localPath.isEmpty) return null;
    final file = File(localPath);
    return file.existsSync() ? file : null;
  }
}
