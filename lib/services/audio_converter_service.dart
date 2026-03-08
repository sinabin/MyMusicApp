import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// FFmpegKit을 이용한 오디오 포맷 변환 서비스.
///
/// [DownloadProvider]에서 다운로드 완료 후 MP3 변환 단계에서 사용.
class AudioConverterService {
  /// [inputPath] 파일을 [bitrate] kbps MP3로 변환하여 [outputPath]에 저장.
  ///
  /// 변환 성공 시 원본 파일을 삭제하고 결과 [File] 반환. 실패 시 예외 발생.
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
