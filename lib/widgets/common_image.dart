import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CommonImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const CommonImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.shopping_bag,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Network Image
    if (imageUrl!.startsWith('http') || imageUrl!.startsWith('https')) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Asset Image
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // kIsWeb check - Image.file will crash on Web
    if (kIsWeb) {
      // On web, if it's not a URL/Asset, we can't easily show a local file path
      return _buildPlaceholder();
    }

    // Local File Image
    String cleanPath = imageUrl!;
    try {
      if (cleanPath.startsWith('file:')) {
        cleanPath = Uri.parse(cleanPath).toFilePath();
      }
    } catch (_) {}

    // Normalize separators for the current platform
    cleanPath = cleanPath.replaceAll('/', Platform.pathSeparator).replaceAll('\\', Platform.pathSeparator);
    
    final file = File(cleanPath);
    return Image.file(
      file,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('CommonImage error for path $cleanPath: $error');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          placeholderIcon,
          size: width != null ? width! * 0.4 : 40,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
