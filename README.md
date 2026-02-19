# The Boxer - Timebox Planner

Flutter로 개발한 타임박스 방식의 모바일 플래너 앱.

---

## 개발 목적

Claude Code **Agent Teams** 기능 테스트를 목적으로 제작된 프로젝트.
백엔드 없이 로컬 저장소만 사용하며, 에이전트 팀이 역할 분담하여 병렬·순차 개발을 수행했다.

---

## 핵심 기능

### 타임박스 캘린더
- 표시 시간대: 05:00 ~ 24:00
- 눈금 단위 선택: 1시간 / 30분 / 10분 / 5분 / 오전·오후·저녁 구간
- 탭으로 타임박스 블록 생성 및 편집

### 카테고리
- 사용자 직접 생성·수정·삭제
- 카테고리별 색상 지정, 타임박스에 시각적으로 표시
- 카테고리 미지정 허용

### 플랜 입력
- **일간 플랜**: 하루 단위 타임박스 일정 입력
- **주간 플랜**: 주 단위 목표/계획, 해당 주가 끝날 때까지 계속 표시
- **루틴**: 반복 항목 미리 등록 후 탭 한 번으로 타임박스에 추가

### 테마
- 컬러 모드 (기본) / 흑백 모드 전환 지원

---

## 기술 스택

| 항목 | 선택 |
|------|------|
| 프레임워크 | Flutter 3.7.9 / Dart 2.19.6 |
| 상태관리 | flutter_riverpod 2.3.7 |
| 로컬 저장소 | Hive 2.2.3 + hive_flutter |
| 유틸리티 | uuid, intl, equatable |
| 백엔드 | 없음 |

---

## 프로젝트 구조

```
lib/
├── main.dart                        # Hive 초기화 + ProviderScope
├── app.dart                         # MaterialApp + 라우팅 + 테마 연결
├── core/
│   ├── constants/app_constants.dart # 전역 상수
│   └── theme/app_theme.dart         # 컬러/흑백 테마 정의
├── data/
│   ├── models/                      # Hive 데이터 모델
│   │   ├── timebox_block.dart       # typeId: 0
│   │   ├── category.dart            # typeId: 1
│   │   ├── routine.dart             # typeId: 2
│   │   ├── weekly_plan.dart         # typeId: 3
│   │   └── time_unit.dart           # 눈금 단위 enum
│   ├── repositories/                # 저장소 추상 인터페이스
│   └── local/                       # Hive 구현체
├── providers/                       # Riverpod 상태관리
│   ├── theme_provider.dart
│   ├── timebox_provider.dart        # timeUnitProvider 포함
│   ├── category_provider.dart
│   ├── routine_provider.dart
│   └── weekly_plan_provider.dart
├── presentation/
│   ├── screens/                     # 화면 5개
│   │   ├── home_screen.dart
│   │   ├── timebox_screen.dart
│   │   ├── weekly_plan_screen.dart
│   │   ├── routine_screen.dart
│   │   └── category_screen.dart
│   └── widgets/                     # 재사용 위젯
│       ├── timebox_calendar/
│       ├── category/
│       └── routine/
└── utils/
    ├── time_utils.dart
    └── color_utils.dart
```

---

## 에이전트 팀 구성

본 프로젝트는 Claude Code Agent Teams 기능으로 개발되었다.

```
[Lead - Opus]  아키텍처 확정, 공유 모델·인터페이스 정의
      ↓ 병렬 실행
[UI - Sonnet]          [Logic - Sonnet]
타임박스 캘린더 UI  ←→  Hive 저장소 + Riverpod 상태관리
      ↓ 완료 후 순차 실행
[Reviewer - Haiku]  →  [Git - Haiku]
코드 리뷰 & 버그 수정     기능 단위 커밋
```

### 에이전트별 산출물

| 에이전트 | 역할 | 주요 산출물 |
|---------|------|------------|
| Lead (Opus) | 아키텍처 | 공유 모델 4개, 리포지토리 인터페이스 4개, ARCHITECTURE.md |
| UI (Sonnet) | UI 레이어 | 화면 5개, 위젯 9개, 테마 |
| Logic (Sonnet) | 로직 레이어 | Hive 구현체 4개, Provider 5개, Hive .g.dart 4개 |
| Reviewer (Haiku) | 코드 리뷰 | BuildContext async 갭 수정, CODE_REVIEW.md |
| Git (Haiku) | 버전 관리 | 기능 단위 커밋 6개 |

---

## 커밋 히스토리

```
a1a7380 chore: configure dependencies (flutter_riverpod, hive, uuid, intl)
716760b docs: add code review report (A+ rating)
4d26279 feat: implement full UI layer with timebox calendar
03bc411 feat: implement Hive repositories and Riverpod providers
127809d feat: define shared data models and repository interfaces
9262b54 chore: init Flutter project with Hive + Riverpod stack
```

---

## 실행 방법

```bash
flutter pub get
flutter run
```

---

## 개발 범위 외 항목

- 리포트 기능: 미구현 (명세 제외)
- 결제 로직: 미구현 (UI 없음)
- 테스트: macOS 보안 정책으로 인한 Flutter tester 차단으로 건너뜀
