/// 시간 관련 유틸리티
class TimeUtils {
  TimeUtils._();

  /// 분(minute)을 "HH:MM" 형태의 문자열로 변환
  /// 예: 570 → "09:30", 1440 → "24:00"
  static String minutesToTimeString(int totalMinutes) {
    assert(totalMinutes >= 0 && totalMinutes <= 1440);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// "HH:MM" 문자열을 분(minute)으로 변환
  static int timeStringToMinutes(String timeString) {
    final parts = timeString.split(':');
    assert(parts.length == 2);
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  /// DateTime에서 날짜만 추출 (시각 정보 제거)
  static DateTime dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// 해당 날짜가 속하는 주의 월요일 반환
  static DateTime getWeekStartDate(DateTime date) {
    final d = dateOnly(date);
    // weekday: 1=월, 7=일
    final daysFromMonday = d.weekday - 1;
    return d.subtract(Duration(days: daysFromMonday));
  }

  /// 두 DateTime이 같은 날짜인지 비교
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 해당 날짜가 오늘인지 확인
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// 두 타임박스 블록이 시간 충돌하는지 확인
  static bool hasTimeConflict(
    int start1, int end1,
    int start2, int end2,
  ) {
    return start1 < end2 && start2 < end1;
  }

  /// 구간명 반환 (오전/오후/저녁)
  static String getSegmentName(int minute) {
    if (minute < 360) return '새벽';   // 0–06시
    if (minute < 720) return '오전';   // 06–12시
    if (minute < 1080) return '오후';  // 12–18시
    return '저녁';                      // 18–24시
  }
}
