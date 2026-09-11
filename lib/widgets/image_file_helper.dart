import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Cross-platform image widget — NO dart:io dependency.
///
/// - On web: path is a blob:// URL (from image_picker), so Image.network works.
/// - On native: converts the file path to a file:// URI, which Image.network
///   also supports on Android/iOS/desktop.
Widget buildFileImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  // On web, XFile.path is already a blob:// URL → Image.network works directly.
  // On native, convert absolute file path to a file:// URI → Image.network works too.
  final String uri = kIsWeb ? path : Uri.file(path).toString();

  return Image.network(
    uri,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder != null
        ? (ctx, err, st) => errorBuilder(ctx, err, st)
        : null,
  );
}
