import 'dart:io';

/// 다운로드된 오디오 파일을 최종 저장 경로로 이동하는 서비스.
///
/// 기존 FFmpeg MP3 변환을 대체. YouTube 오디오 스트림(m4a)을
/// 변환 없이 그대로 저장하며, [DownloadProvider]에서 사용.
class AudioConverterService {
  /// [inputPath]의 임시 파일을 [outputPath]로 이동.
  ///
  /// 이동 성공 시 결과 [File] 반환. 실패 시 예외 발생.
  Future<File?> moveToOutput({
    required String inputPath,
    required String outputPath,
  }) async {
    final inputFile = File(inputPath);
    try {
      // 같은 파일시스템이면 rename(빠름), 아니면 copy 후 삭제
      return await inputFile.rename(outputPath);
    } on FileSystemException {
      final copied = await inputFile.copy(outputPath);
      await inputFile.delete();
      return copied;
    }
  }
}
