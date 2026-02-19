# Timebox Planner - Architecture Spec

팀장(Lead)이 확정한 아키텍처 명세. Wave 1 에이전트는 이 문서를 기준으로 작업한다.

---

## 기술 스택 결정

| 항목 | 선택 | 이유 |
|------|------|------|
| 상태관리 | **flutter_riverpod ^2.3.6** | 코드 생성 기반, 타입 안전, 테스트 용이 |
| 로컬 저장소 | **Hive ^2.2.3 + hive_flutter** | 복잡한 객체 직렬화, 빠른 읽기/쓰기 |
| 유틸리티 | uuid ^3.0.7, intl ^0.18.1, equatable ^2.0.5 | ID 생성, 날짜 포맷, 값 비교 |

---

## 프로젝트 구조

```
lib/
├── main.dart                         # 앱 진입점, Hive 초기화
├── app.dart                          # MaterialApp + Riverpod ProviderScope
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # 전역 상수 (dayStartMinute=300, Box 이름 등)
│   └── theme/
│       └── app_theme.dart            # 컬러/흑백 테마 정의
├── data/
│   ├── models/                       # Hive 데이터 클래스 (팀장이 확정)
│   │   ├── timebox_block.dart        # typeId: 0
│   │   ├── category.dart             # typeId: 1
│   │   ├── routine.dart              # typeId: 2
│   │   ├── weekly_plan.dart          # typeId: 3
│   │   └── time_unit.dart            # enum (Hive 저장 불필요, 설정에 int로 저장)
│   ├── repositories/                 # 추상 인터페이스 (팀장이 확정)
│   │   ├── timebox_repository.dart
│   │   ├── category_repository.dart
│   │   ├── routine_repository.dart
│   │   └── weekly_plan_repository.dart
│   └── local/                        # [로직 에이전트 담당] Hive 구현체
│       ├── hive_timebox_repository.dart
│       ├── hive_category_repository.dart
│       ├── hive_routine_repository.dart
│       └── hive_weekly_plan_repository.dart
├── providers/                        # [로직 에이전트 담당] Riverpod providers
│   ├── timebox_provider.dart
│   ├── category_provider.dart
│   ├── routine_provider.dart
│   ├── weekly_plan_provider.dart
│   └── theme_provider.dart
├── presentation/
│   ├── screens/                      # [UI 에이전트 담당]
│   │   ├── home_screen.dart          # 메인 화면 (날짜 선택 + 타임박스 뷰)
│   │   ├── timebox_screen.dart       # 타임박스 편집 화면
│   │   ├── weekly_plan_screen.dart   # 주간 플랜 입력 화면
│   │   ├── routine_screen.dart       # 루틴 관리 화면
│   │   └── category_screen.dart      # 카테고리 관리 화면
│   └── widgets/                      # [UI 에이전트 담당]
│       ├── timebox_calendar/
│       │   ├── timebox_calendar_widget.dart  # 메인 캘린더 컨테이너
│       │   ├── time_ruler_widget.dart        # 좌측 시간 눈금
│       │   ├── timebox_block_widget.dart     # 개별 타임박스 블록
│       │   └── time_grid_widget.dart         # 배경 그리드
│       ├── category/
│       │   ├── category_chip_widget.dart
│       │   └── category_color_picker_widget.dart
│       └── routine/
│           └── routine_selector_widget.dart
└── utils/
    ├── time_utils.dart               # 시간 변환 유틸 (팀장이 확정)
    └── color_utils.dart              # 색상 유틸 (팀장이 확정)
```

---

## 데이터 모델 (팀장 확정 - 수정 금지)

### Hive typeId 할당표

| 모델 | typeId |
|------|--------|
| TimeboxBlock | 0 |
| Category | 1 |
| Routine | 2 |
| WeeklyPlan | 3 |

### TimeboxBlock
```dart
class TimeboxBlock {
  String id;
  DateTime date;       // 날짜만 사용 (시각 제거)
  int startMinute;     // 자정 기준 분 단위 (0–1440)
  int endMinute;       // 자정 기준 분 단위 (0–1440)
  String title;
  String? description;
  String? categoryId;  // null = 카테고리 미지정
  String? routineId;   // null = 루틴과 무관
}
```

### Category
```dart
class Category {
  String id;
  String name;
  int colorValue;  // Color.value (ARGB integer)
}
```

### Routine
```dart
class Routine {
  String id;
  String title;
  int durationMinutes;  // 기본 지속 시간
  String? categoryId;
  String? description;
}
```

### WeeklyPlan
```dart
class WeeklyPlan {
  String id;
  DateTime weekStartDate;  // 해당 주 월요일 (날짜만 사용)
  String content;
  List<String> goals;
}
```

---

## Hive Box 구성

| Box 이름 | 키 타입 | 값 타입 |
|----------|---------|---------|
| `timeboxes` | String (id) | TimeboxBlock |
| `categories` | String (id) | Category |
| `routines` | String (id) | Routine |
| `weekly_plans` | String (id) | WeeklyPlan |
| `settings` | String | dynamic |

---

## 시간 시스템

- **표시 범위**: 05:00 (300분) ~ 24:00 (1440분)
- **저장 방식**: 자정(00:00)부터의 분 단위 정수
  - 예) 09:30 → 570, 14:00 → 840
- **눈금 단위** (TimeUnit enum):
  - `oneHour` → 60분 간격
  - `thirtyMinutes` → 30분 간격
  - `tenMinutes` → 10분 간격
  - `fiveMinutes` → 5분 간격
  - `morning` → 오전 구간 (06:00–12:00)
  - `afternoon` → 오후 구간 (12:00–18:00)
  - `evening` → 저녁 구간 (18:00–24:00)

---

## 테마 시스템

- `isColorMode` 설정값 (Hive settings box, 기본값: `true`)
- **컬러 모드 (true)**: Material 기본 색상, 카테고리 색상 그대로 표시
- **흑백 모드 (false)**: 카테고리 색상을 그레이스케일로 변환, 모노크롬 UI
- 현재 개발에서는 컬러 모드를 기본으로 작동

---

## 상태 관리 가이드 (Riverpod)

### Provider 목록

| Provider | 타입 | 역할 |
|----------|------|------|
| `themeProvider` | StateNotifierProvider<ThemeNotifier, bool> | isColorMode 상태 |
| `timeUnitProvider` | StateProvider<TimeUnit> | 선택된 눈금 단위 |
| `selectedDateProvider` | StateProvider<DateTime> | 현재 선택된 날짜 |
| `categoriesProvider` | StreamProvider<List<Category>> | 카테고리 목록 실시간 |
| `routinesProvider` | StreamProvider<List<Routine>> | 루틴 목록 실시간 |
| `timeboxBlocksProvider(DateTime)` | FutureProvider<List<TimeboxBlock>> | 날짜별 블록 |
| `currentWeeklyPlanProvider` | FutureProvider<WeeklyPlan?> | 현재 주 플랜 |

---

## 주간 플랜 날짜 로직

```dart
// WeeklyPlan.isCurrentWeek() 메서드 사용
// 조건: weekStartDate(월요일) <= today <= weekEndDate(일요일)
// 해당 주가 지나지 않았으면 계속 표시
```

---

## 코드 생성

Hive 어댑터만 build_runner로 생성 (Riverpod은 수동 작성):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

생성 파일:
- `lib/data/models/*.g.dart` (Hive TypeAdapter)

Riverpod Provider는 @riverpod annotation 없이 수동 작성.
(Dart SDK 2.19.6 환경에서 riverpod_generator 미사용)

---

## 분업 경계

### UI 에이전트 담당
- `lib/presentation/` 전체
- `lib/core/theme/app_theme.dart`
- `lib/app.dart`

### 로직 에이전트 담당
- `lib/data/local/` 전체 (Hive 구현체)
- `lib/providers/` 전체
- `lib/main.dart` (Hive 초기화)

### 공유 (수정 금지)
- `lib/data/models/` 전체
- `lib/data/repositories/` 전체
- `lib/utils/` 전체
- `lib/core/constants/app_constants.dart`
