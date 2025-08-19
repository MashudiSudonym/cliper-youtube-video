import 'dart:io';
import 'package:path/path.dart' as p;

class FFmpegHelper {
  static String get ffmpegPath {
    // Ambil working directory saat ini
    final currentDir = Directory.current.path;
    final binDir = p.join(currentDir, 'bin');

    if (Platform.isWindows) {
      return p.join(binDir, 'ffmpeg.exe');
    } else {
      return p.join(binDir, 'ffmpeg');
    }
  }
}
