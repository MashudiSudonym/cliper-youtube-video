import 'package:interact/interact.dart';
import 'package:cliper/downloader.dart';
import 'package:cliper/splitter.dart';

void main(List<String> arguments) async {
  print('🎬 Welcome to CLIper (YouTube video clipper)\n');

  final url = Input(prompt: 'Masukkan URL YouTube').interact();

  final duration = Input(
    prompt: 'Durasi tiap segmen (detik)',
    defaultValue: '60',
  ).interact();

  print('⬇️  Downloading video...');

  // Downloader sekarang mengembalikan path file yang sudah di-download
  final outputFile = await Downloader.downloadVideo(url);

  print(outputFile);
  print('✂️  Splitting video...');
  await Splitter.splitAndCropVideo(outputFile, int.parse(duration));

  print('✅ Selesai! Video sudah dipotong menjadi klip.');
}
