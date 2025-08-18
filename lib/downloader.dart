import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Downloader {
  static String getHomeDirectory() {
    if (Platform.isLinux || Platform.isMacOS) {
      return Platform.environment['HOME'] ?? '/tmp';
    } else if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? r'C:\Temp';
    } else {
      return '/tmp';
    }
  }

  /// Mengunduh video dari YouTube dan mengembalikan path file hasil download
  static Future<String> downloadVideo(String url) async {
    final yt = YoutubeExplode();

    try {
      // Ambil info video
      var video = await yt.videos.get(url);
      print('🎥 Judul video: ${video.title}');
      print('⏱ Durasi: ${video.duration}');

      // Sanitasi judul video untuk jadi nama folder/file (hapus karakter ilegal)
      var safeTitle = video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

      // Folder cross-platform
      var homeDir = getHomeDirectory();
      var baseFolder = '$homeDir/Videos/$safeTitle';
      await Directory(baseFolder).create(recursive: true);

      var outputFile = '$baseFolder/$safeTitle.mp4'; // Ambil stream manifest
      var manifest = await yt.videos.streamsClient.getManifest(video.id);

      if (manifest.muxed.isNotEmpty) {
        // Jika ada muxed stream, pakai yang terbaik
        var streamInfo = manifest.muxed.withHighestBitrate();
        var stream = yt.videos.streamsClient.get(streamInfo);

        var file = File(outputFile);
        var fileStream = file.openWrite();
        await stream.pipe(fileStream);
        await fileStream.flush();
        await fileStream.close();

        print('✅ Download selesai: $outputFile');
      } else if (manifest.videoOnly.isNotEmpty &&
          manifest.audioOnly.isNotEmpty) {
        // Fallback: ambil videoOnly + audioOnly lalu merge via ffmpeg
        var videoStreamInfo = manifest.videoOnly.withHighestBitrate();
        var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

        var videoFile = '$baseFolder/video_temp.mp4';
        var audioFile = '$baseFolder/audio_temp.mp3';

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
          outputFile,
        ]);

        // Hapus temporary file
        await File(videoFile).delete();
        await File(audioFile).delete();

        if (result.exitCode != 0) {
          print('❌ Error merge video+audio: ${result.stderr}');
          exit(1);
        }

        print('✅ Download selesai dan merge: $outputFile');
      } else {
        print('❌ Tidak ada stream video/audio yang tersedia.');
        exit(1);
      }

      // Kembalikan path file hasil download
      return outputFile;
    } catch (e) {
      print('❌ Error saat download: $e');
      exit(1);
    } finally {
      yt.close();
    }
  }
}
