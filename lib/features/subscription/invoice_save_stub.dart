import 'dart:typed_data';

/// Non-web fallback: browser download is not supported on this platform.
Future<void> savePdfInBrowser(Uint8List bytes, String filename) {
  throw UnsupportedError('Browser download is only supported on web');
}
