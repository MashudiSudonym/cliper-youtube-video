import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Downloader {
  static Future<void> downloadVideo(String url, String output) async {
    final yt = YoutubeExplode();

    try {
      // Ambil info video
      var video = await yt.videos.get(url);
      print('🎥 Judul video: ${video.title}');
      print('⏱ Durasi: ${video.duration}');

      // Ambil stream manifest
      var manifest = await yt.videos.streamsClient.getManifest(video.id);

      if (manifest.muxed.isNotEmpty) {
        // Jika ada muxed stream, pakai yang terbaik
        var streamInfo = manifest.muxed.withHighestBitrate();
        var stream = yt.videos.streamsClient.get(streamInfo);

        var file = File(output);
        var fileStream = file.openWrite();
        await stream.pipe(fileStream);
        await fileStream.flush();
        await fileStream.close();

        print('✅ Download selesai: $output');
      } else if (manifest.videoOnly.isNotEmpty &&
          manifest.audioOnly.isNotEmpty) {
        // Fallback: ambil videoOnly + audioOnly lalu merge via ffmpeg
        var videoStreamInfo = manifest.videoOnly.withHighestBitrate();
        var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

        var videoFile = 'video_temp.mp4';
        var audioFile = 'audio_temp.mp3';

        // Download video
        var videoStream = yt.videos.streamsClient.get(videoStreamInfo);
        var videoOut = File(videoFile).openWrite();
        await videoStream.pipe(videoOut);
        await videoOut.flush();
        await videoOut.close();

        // Download audio
        var audioStream = yt.videos.streamsClient.get(audioStreamInfo);
        var audioOut = File(audioFile).openWrite();
        await audioStream.pipe(audioOut);
        await audioOut.flush();
        await audioOut.close();

        // Merge pakai ffmpeg
        var result = await Process.run('ffmpeg', [
          '-y',
          '-i',
          videoFile,
          '-i',
          audioFile,
          '-c:v',
          'copy',
          '-c:a',
          'aac',
          output,
        ]);

        // Hapus temporary file
        await File(videoFile).delete();
        await File(audioFile).delete();

        if (result.exitCode != 0) {
          print('❌ Error merge video+audio: ${result.stderr}');
          exit(1);
        }

        print('✅ Download selesai dan merge: $output');
      } else {
        print('❌ Tidak ada stream video/audio yang tersedia.');
        exit(1);
      }
    } catch (e) {
      print('❌ Error saat download: $e');
      exit(1);
    } finally {
      yt.close();
    }
  }
}
