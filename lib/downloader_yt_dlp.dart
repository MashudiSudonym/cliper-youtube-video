import 'dart:io';

class Downloader {
  static Future<void> downloadVideo(String url, String output) async {
    final result = await Process.run('yt-dlp', [
      '-f',
      'bestvideo+bestaudio',
      '--merge-output-format',
      'mp4',
      url,
      '-o',
      output,
    ]);

    if (result.exitCode != 0) {
      print('❌ Error saat download: ${result.stderr}');
      exit(1);
    } else {
      print('✅ Download selesai: $output');
    }
  }
}
