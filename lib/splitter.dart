import 'dart:io';
import 'package:path/path.dart' as p;

class Splitter {
  static Future<void> splitAndCropVideo(
    String input,
    int segmentSeconds,
  ) async {
    // Ambil folder dari path input
    final folder = p.dirname(input);

    // Format output tiap segmen di folder yang sama
    final outputPattern = p.join(folder, 'clip_%03d.mp4');

    // FFmpeg command
    final result = await Process.run('ffmpeg', [
      '-i',
      input,
      '-vf',
      'crop=in_h*9/16:in_h,scale=1080:1920', // crop + scale ke portrait 9:16 Full HD
      '-c:v',
      'libx264', // codec video
      '-preset',
      'veryfast', // speed/quality tradeoff
      '-crf',
      '28', // kualitas video (lebih kecil = lebih bagus)
      '-c:a',
      'aac', // codec audio
      '-b:a',
      '128k',
      '-f',
      'segment',
      '-segment_time',
      segmentSeconds.toString(),
      outputPattern,
    ]);

    if (result.exitCode != 0) {
      print('❌ Error saat split+crop: ${result.stderr}');
      exit(1);
    } else {
      print(
        '✅ Video berhasil dipotong menjadi segmen $segmentSeconds detik dan di-crop 9:16.',
      );
    }
  }
}
