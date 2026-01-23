import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  /// Compresses an image file.
  /// Returns the compressed file or the original if compression fails.
  static Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      // Create a unique target path for the compressed image
      final targetPath = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Good balance between size and quality
        minWidth: 1920, // Max width 1080p equivalentish
        minHeight: 1080,
      );

      if (result != null) {
        final originalSize = await file.length();
        final compressedSize = await result.length();
        print(
          'Image Compressed: ${(originalSize / 1024).toStringAsFixed(2)}KB -> ${(compressedSize / 1024).toStringAsFixed(2)}KB',
        );
        return File(result.path);
      } else {
        return file;
      }
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Fallback to original
    }
  }
}
