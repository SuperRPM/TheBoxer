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
}

extension TimeUnitExtension on TimeUnit {
  /// 눈금 단위를 분 단위로 반환
  int get minuteInterval {
    switch (this) {
      case TimeUnit.oneHour:
        return 60;
      case TimeUnit.thirtyMinutes:
        return 30;
      case TimeUnit.tenMinutes:
        return 10;
      case TimeUnit.fiveMinutes:
        return 5;
    }
  }

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
    }
  }
}
