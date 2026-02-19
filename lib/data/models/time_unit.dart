/// 타임박스 눈금 단위 열거형
enum TimeUnit {
  /// 1시간 (60분)
  oneHour,

  /// 30분
  thirtyMinutes,

  /// 10분
  tenMinutes,

  /// 5분
  fiveMinutes,

  /// 오전 구간 (06–12시)
  morning,

  /// 오후 구간 (12–18시)
  afternoon,

  /// 저녁 구간 (18–24시)
  evening,
}

extension TimeUnitExtension on TimeUnit {
  /// 눈금 단위를 분 단위로 반환 (구간 단위는 null)
  int? get minuteInterval {
    switch (this) {
      case TimeUnit.oneHour:
        return 60;
      case TimeUnit.thirtyMinutes:
        return 30;
      case TimeUnit.tenMinutes:
        return 10;
      case TimeUnit.fiveMinutes:
        return 5;
      default:
        return null; // 구간 단위
    }
  }

  /// 구간 단위 여부
  bool get isSegment =>
      this == TimeUnit.morning ||
      this == TimeUnit.afternoon ||
      this == TimeUnit.evening;

  String get displayLabel {
    switch (this) {
      case TimeUnit.oneHour:
        return '1시간';
      case TimeUnit.thirtyMinutes:
        return '30분';
      case TimeUnit.tenMinutes:
        return '10분';
      case TimeUnit.fiveMinutes:
        return '5분';
      case TimeUnit.morning:
        return '오전';
      case TimeUnit.afternoon:
        return '오후';
      case TimeUnit.evening:
        return '저녁';
    }
  }
}
