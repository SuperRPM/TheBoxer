# TheBoxer 개발 보고서

> 작성일: 2026-02-21
> 패키지: `timebox_planner`
> 기술 스택: Flutter + Riverpod + Hive

---

## 1. 프로젝트 개요

TimeboxCalendar 기반의 생산성 앱. 하루를 시간 블록으로 분할해 관리하는 "타임박싱" 기법을 브레인 덤핑, 주간 계획과 결합한 종합 플래너.

---

## 2. 초기 구조 (before)

| 탭 | 설명 |
|----|------|
| 오늘 | 타임박스 캘린더 |
| 카테고리 | 카테고리 CRUD |
| 주간 | 주간 계획 |
| 루틴 | 반복 일정 관리 |

- FAB: 새 타임박스 생성 (시간+제목+카테고리+루틴 직접 입력)
- 타임박스 블록에 카테고리 색상 적용
- 루틴에 기본 지속 시간(`durationMinutes`) 설정

---

## 3. 전체 개편 내역 (after)

### 3.1 탭 구조 변경

| 탭 | 설명 |
|----|------|
| 오늘 | 브레인덤핑 인박스 + 주간목표 + 타임박스 캘린더 |
| 브레인덤핑 | 생각 목록 관리 (중요/일반/완료 섹션) |
| 주간 | 주간 계획 |
| 루틴 | 루틴 목록 (제목+설명만) |

### 3.2 카테고리 기능 완전 제거

- `CategoryScreen` 라우트 제거 (`app.dart`)
- 타임박스 생성/편집 화면에서 카테고리 UI 제거
- `TimeboxBlock.categoryId`, `Routine.categoryId`: Hive 하위 호환성을 위해 필드는 유지하되 UI에서 미사용
- 타임박스 블록 색상: 카테고리 색상 → `block.id.hashCode` 기반 팔레트(5색)로 대체

### 3.3 FAB 변경

- 이전: `+` 아이콘 → 타임박스 생성 다이얼로그
- 이후: Inbox 아이콘 → `_PlacementSheet` (브레인덤핑/루틴 선택 패널)

### 3.4 배치 모드 (Placement Mode) 신규 구현

```
[FAB 탭] → _PlacementSheet (브레인덤핑 + 루틴 목록)
    ↓ 항목 선택
[PendingPlacement 상태 저장] → _PlacementBanner 표시 (취소 버튼 포함)
    ↓ 캘린더 첫 번째 셀 탭
[_placementStartMinute 설정] → 파란 하이라이트 표시
    ↓ 캘린더 두 번째 셀 탭
[TimeboxBlock 생성 + 브레인덤핑 완료 처리 + 모드 종료]
```

- `lib/providers/placement_provider.dart` 신규 파일
- `PendingItemType` enum: `brainDump`, `routine`
- `PendingPlacement` 클래스: itemId, title, description, type, startMinute
- `PlacementNotifier`: `startPlacement()`, `setStartMinute()`, `clearPlacement()`

### 3.5 캘린더 일반 탭 비활성화

- 빈 셀 탭으로 새 타임박스 생성하는 기능 제거
- `onTapToCreate: (_) {}` 로 콜백 무력화
- 배치 모드 진입 시에만 셀 탭 활성

---

## 4. 브레인 덤핑 기능 개선

### 4.1 별표(중요) 기능 추가

- 각 항목 우측: `Icons.star` / `Icons.star_border` 토글 버튼
- 별표 항목은 목록 최상단 "중요" 섹션에 최대 5개 표시
- 5개 초과 시 `toggleStar()` 호출 차단

```dart
// brain_dump_provider.dart
Future<void> toggleStar(String id) async {
  final item = state.firstWhere((i) => i.id == id);
  final starredCount = state.where((i) => i.isStarred).length;
  if (!item.isStarred && starredCount >= 5) return; // 5개 제한
  await _repo.toggleStar(id);
  _load();
}
```

### 4.2 오늘 탭 인박스 스트립

- 이전: 미완료 항목 전체 표시
- 이후: 별표(중요) 항목만 표시

### 4.3 입력창 UX 개선

- `+` 버튼 제거 → 엔터키만으로 항목 추가
- 빈 화면 터치 시 키보드 자동 닫기

### 4.4 목록 섹션 구조

| 섹션 | 아이콘 | 조건 |
|------|--------|------|
| 중요 | ⭐ 황금 | `isStarred && !isChecked` (최대 5개) |
| 할 일 | 📥 | `!isChecked && !isStarred` |
| 완료 | ✅ | `isChecked` |

---

## 5. 루틴 기능 개선

- 제목 + 설명 필드만 유지 (카테고리, 지속시간 제거)
- `Routine.durationMinutes` 기본값 → 0, `assert(durationMinutes > 0)` 제거
- 루틴 추가 다이얼로그: 제목 필드에 자동 포커스(`autofocus: true`)
- 설명 필드에서 엔터 → 저장 (`onFieldSubmitted: (_) => _save()`)

---

## 6. 주간 목표 표시 개선

- `maxLines: 1` 제거 → 여러 줄 목표 내용 전체 표시

---

## 7. 타임박스 블록 삭제 시 브레인 덤핑 복원

- `TimeboxBlock`에 `brainDumpItemId` 필드(HiveField 8) 추가
- 배치 시 `brainDumpItemId` 저장
- 블록 삭제 시: `brainDumpItemId != null`이고 해당 항목이 완료 상태면 → 미완료로 복원

```dart
// timebox_screen.dart - _delete()
if (block.brainDumpItemId != null) {
  final items = ref.read(brainDumpProvider);
  final item = items.where((i) => i.id == block.brainDumpItemId).firstOrNull;
  if (item != null && item.isChecked) {
    await ref.read(brainDumpProvider.notifier).toggle(block.brainDumpItemId!);
  }
}
```

---

## 8. 캘린더 레이아웃 변경

### 이전 구조 (7 시각적 컬럼)
```
[시간 레이블 열 52px] | [그리드 col1] | [col2] | [col3] | [col4] | [col5] | [col6]
```

### 이후 구조 (6 시각적 컬럼)
```
[col1 + 시간 레이블 오버레이] | [col2] | [col3] | [col4] | [col5] | [col6]
```

- 별도 레이블 열 제거 → `Stack`의 `Positioned` 위젯으로 첫 번째 셀 좌상단에 시간 표시
- `fontSize: 10`, `Colors.grey[500]` 스타일
- 그리드 가로 공간을 100% 활용

---

## 9. UX 디테일

| 개선사항 | 파일 |
|----------|------|
| 빈 화면 터치 시 키보드 닫기 | `home_screen.dart`, `brain_dump_screen.dart`, `routine_screen.dart` |
| 배치 완료 스낵바 제거 | `home_screen.dart` |
| 배치 모드 중 블록 탭 비활성 | `timebox_calendar_widget.dart` |
| AppBar ⚡ 버튼으로 브레인덤핑 빠른 추가 | `home_screen.dart` |

---

## 10. Hive 모델 변경 내역

### BrainDumpItem (typeId: 1)

| Field | HiveField | 변경 |
|-------|-----------|------|
| id | 0 | - |
| content | 1 | - |
| isChecked | 2 | - |
| createdAt | 3 | - |
| **isStarred** | **4** | **신규 추가** |

### TimeboxBlock (typeId: 0)

| Field | HiveField | 변경 |
|-------|-----------|------|
| id | 0 | - |
| date | 1 | - |
| startMinute | 2 | - |
| endMinute | 3 | - |
| title | 4 | - |
| description | 5 | - |
| categoryId | 6 | - |
| routineId | 7 | - |
| **brainDumpItemId** | **8** | **신규 추가** |

> **하위 호환성 처리**: `.g.dart` 어댑터에서 신규 필드 읽기 시
> `fields[N] as Type? ?? defaultValue` 패턴 사용 (기존 저장 데이터 보호)

---

## 11. 신규 파일 목록

| 파일 | 설명 |
|------|------|
| `lib/providers/placement_provider.dart` | 배치 모드 상태 관리 |
| `lib/data/models/brain_dump_item.dart` | isStarred 필드 추가 |
| `lib/data/models/brain_dump_item.g.dart` | Hive 어댑터 업데이트 |
| `lib/presentation/screens/brain_dump_screen.dart` | 브레인 덤핑 화면 전면 개편 |
| `lib/providers/brain_dump_provider.dart` | toggleStar 메서드 추가 |
| `lib/data/local/hive_brain_dump_repository.dart` | toggleStar 구현 |

---

## 12. 주요 수정 파일 목록

| 파일 | 주요 변경 |
|------|----------|
| `lib/app.dart` | `/category` 라우트 제거 |
| `lib/data/models/timebox_block.dart` | brainDumpItemId 필드 추가 |
| `lib/data/models/timebox_block.g.dart` | Hive 어댑터 9필드로 업데이트 |
| `lib/data/models/routine.dart` | durationMinutes 기본값 0, assert 제거 |
| `lib/presentation/screens/home_screen.dart` | 전면 개편 (배치 모드, FAB 변경) |
| `lib/presentation/screens/timebox_screen.dart` | 카테고리 UI 제거, 브레인덤핑 복원 로직 |
| `lib/presentation/screens/routine_screen.dart` | 간소화 (제목+설명만) |
| `lib/presentation/widgets/timebox_calendar/timebox_calendar_widget.dart` | 배치 모드 지원, 레이아웃 개편 |
| `lib/presentation/widgets/routine/routine_selector_widget.dart` | 카테고리/시간 UI 제거 |
| `lib/providers/timebox_provider.dart` | addFromRoutine 시그니처 변경 |

---

## 13. 개발 환경 참고 사항

- **WSL에서 Flutter 직접 실행 불가**: `/mnt/d/flutter/bin/flutter`는 Windows CRLF 스크립트
- **배포 명령어**: `powershell.exe -Command "cd 'C:\Users\vidaf\project\TheBoxer'; flutter run -d R39M208A5KD"`
- **Git 인증**: `credential.helper=/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe`

---

## 14. 미결/보류 항목

| 항목 | 상태 |
|------|------|
| 주간 플랜 체크리스트 제거 | 보류 (사용자 요청) |
| 화면 구성 조정 | 보류 (사용자 추후 논의 예정) |
