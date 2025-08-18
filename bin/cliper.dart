import 'package:interact/interact.dart';
import 'package:cliper/downloader.dart';
import 'package:cliper/splitter.dart';

void main(List<String> arguments) async {
  print('🎬 Welcome to CLIper (YouTube video clipper)\n');

  final url = Input(prompt: 'Masukkan URL youtube').interact();

  final duration = Input(
    prompt: 'Durasi tiap segmen (detik)',
    defaultValue: '60',
  ).interact();

  final output = 'video.mp4';

  print('⬇️  Downloading video...');
  await Downloader.downloadVideo(url, output);

  print('✂️  Splitting video...');
  await Splitter.splitAndCropVideo(output, int.parse(duration));

  print('✅ Selesai! Video sudah dipotong menjadi klip.');
}
