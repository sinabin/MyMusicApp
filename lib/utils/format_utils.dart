import 'package:intl/intl.dart';
import '../models/download_item.dart';

/// 파일 크기·시간·날짜를 사용자 친화적 문자열로 변환하는 유틸리티.
class FormatUtils {
  FormatUtils._();

  /// [bytes]를 B/KB/MB/GB 단위 문자열로 변환.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// [Duration]을 "H:MM:SS" 또는 "M:SS" 형식 문자열로 변환.
  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// [DateTime]을 상대적 날짜 문자열로 변환. 오늘이면 "Today HH:mm", 어제면 "Yesterday HH:mm" 반환.
  static String date(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    if (dateOnly == today) {
      return 'Today ${DateFormat.Hm().format(dt)}';
    }
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat.Hm().format(dt)}';
    }
    return DateFormat('MM/dd HH:mm').format(dt);
  }

  /// 곡 수 포맷 ("1 song" / "N songs").
  static String trackCount(int count) =>
      count == 1 ? '1 song' : '$count songs';

  /// 곡 목록의 총 재생 시간 포맷.
  static String totalDuration(List<DownloadItem> items) {
    final totalMs = items.fold<int>(
      0,
      (sum, item) => sum + (item.durationInMs ?? 0),
    );
    return duration(Duration(milliseconds: totalMs));
  }

  /// [DateTime]을 시간 구간 레이블로 변환 ("Today", "Yesterday", "This Week", "Earlier").
  static String timeGroupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Earlier';
  }
}
