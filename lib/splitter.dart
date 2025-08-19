import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

class Splitter {
  static Future<void> splitAndCropVideo(
    String input,
    int segmentSeconds,
  ) async {
    final folder = p.dirname(input);
    final outputPattern = p.join(folder, 'clip_%03d.mp4');

    // Ambil durasi total video via ffmpeg probe
    final probe = await Process.run('bin/ffmpeg', [
      '-i',
      input,
      '-hide_banner',
    ]);

    final regex = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)');
    final match = regex.firstMatch(probe.stderr);
    double totalSeconds = 0;
    if (match != null) {
      final h = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final s = double.parse(match.group(3)!);
      totalSeconds = h * 3600 + m * 60 + s;
    }

    // Jalankan ffmpeg dengan Process.start biar bisa baca output realtime
    final process = await Process.start('bin/ffmpeg', [
      '-i',
      input,
      '-vf',
      'crop=in_h*9/16:in_h,scale=1080:1920',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '28',
      '-c:a',
      'aac',
      '-b:a',
      '128k',
      '-f',
      'segment',
      '-segment_time',
      segmentSeconds.toString(),
      outputPattern,
      '-y',
    ], mode: ProcessStartMode.normal);

    // Parsing progress dari stderr
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((
      line,
    ) {
      final match = RegExp(r'time=(\d+):(\d+):(\d+\.\d+)').firstMatch(line);
      if (match != null && totalSeconds > 0) {
        final h = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final s = double.parse(match.group(3)!);
        final current = h * 3600 + m * 60 + s;

        final percent = (current / totalSeconds * 100).clamp(0, 100);
        stdout.write(
          '\r✂️  Splitting... ${percent.toStringAsFixed(2)}% (${current.toStringAsFixed(1)}s/${totalSeconds.toStringAsFixed(1)}s)',
        );
      }
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('\n❌ Error saat split+crop video.');
      exit(1);
    } else {
      print('\n✅ Video berhasil dipotong & crop jadi portrait.');
    }
  }
}
