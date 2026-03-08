import 'dart:io';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';

class AudioConverterService {
  Future<File?> convertToMp3({
    required String inputPath,
    required String outputPath,
    int bitrate = 320,
    void Function(double progress)? onProgress,
  }) async {
    final command = '-i "$inputPath" -vn -ar 44100 -ac 2 -b:a ${bitrate}k "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      // Clean up input file
      try {
        await File(inputPath).delete();
      } catch (_) {}
      return File(outputPath);
    } else {
      final logs = await session.getAllLogsAsString();
      throw Exception('FFmpeg conversion failed: $logs');
    }
  }
}
