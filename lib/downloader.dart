import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Downloader {
  static String getHomeDirectory() {
    if (Platform.isLinux || Platform.isMacOS) {
      return Platform.environment['HOME'] ?? '/tmp';
    } else if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? r'C:\\Temp';
    } else {
      return '/tmp';
    }
  }

  /// Menampilkan progress bar sederhana di terminal
  static void showProgress(String label, int downloaded, int total) {
    final percent = (downloaded / total * 100).clamp(0, 100);
    stdout.write(
      '\r$label ${percent.toStringAsFixed(2)}% (${(downloaded / 1024 / 1024).toStringAsFixed(1)}MB/${(total / 1024 / 1024).toStringAsFixed(1)}MB)',
    );
  }

  /// Mengunduh video YouTube (videoOnly + audioOnly) dengan progress bar
  static Future<String> downloadVideo(String url) async {
    final yt = YoutubeExplode();

    try {
      var video = await yt.videos.get(url);
      print('🎥 Judul video: ${video.title}');
      print('⏱ Durasi: ${video.duration}');

      var safeTitle = video.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      var homeDir = getHomeDirectory();
      var baseFolder = '$homeDir/Videos/$safeTitle';
      await Directory(baseFolder).create(recursive: true);

      var outputFile = '$baseFolder/$safeTitle.mp4';
      var manifest = await yt.videos.streamsClient.getManifest(video.id);

      if (manifest.videoOnly.isEmpty || manifest.audioOnly.isEmpty) {
        print('❌ Tidak ada stream video/audio yang tersedia.');
        exit(1);
      }

      // Ambil stream terbaik
      var videoStreamInfo = manifest.videoOnly.withHighestBitrate();
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      var videoFile = '$baseFolder/video_temp.mp4';
      var audioFile = '$baseFolder/audio_temp.mp3';

      // Download videoOnly
      print('\n⬇️  Download video stream...');
      var videoStream = yt.videos.streamsClient.get(videoStreamInfo);
      var videoSize = videoStreamInfo.size.totalBytes;
      int videoDownloaded = 0;

      var videoOut = File(videoFile).openWrite();
      await for (var data in videoStream) {
        videoDownloaded += data.length;
        videoOut.add(data);
        showProgress("Video", videoDownloaded, videoSize);
      }
      await videoOut.flush();
      await videoOut.close();
      print('\n✅ Video stream selesai.');

      // Download audioOnly
      print('\n⬇️  Download audio stream...');
      var audioStream = yt.videos.streamsClient.get(audioStreamInfo);
      var audioSize = audioStreamInfo.size.totalBytes;
      int audioDownloaded = 0;

      var audioOut = File(audioFile).openWrite();
      await for (var data in audioStream) {
        audioDownloaded += data.length;
        audioOut.add(data);
        showProgress("Audio", audioDownloaded, audioSize);
      }
      await audioOut.flush();
      await audioOut.close();
      print('\n✅ Audio stream selesai.');

      // Merge dengan ffmpeg
      print('\n🔗 Merge video+audio...');
      var result = await Process.run('bin/ffmpeg', [
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

      // Hapus file sementara
      await File(videoFile).delete();
      await File(audioFile).delete();

      if (result.exitCode != 0) {
        print('❌ Error merge video+audio: ${result.stderr}');
        exit(1);
      }

      print('✅ Download & merge selesai: $outputFile');
      return outputFile;
    } catch (e) {
      print('❌ Error saat download: $e');
      exit(1);
    } finally {
      yt.close();
    }
  }
}
