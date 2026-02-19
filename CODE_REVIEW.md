# 코드 리뷰 결과

## 직접 수정한 사항

### 1. BuildContext async 갭 수정
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/timebox_screen.dart`
- **라인**: 197-201
- **수정 내용**: `_showError()` 메서드에서 `ScaffoldMessenger.of(context)` 호출 전 `mounted` 체크 추가
  - **이유**: 비동기 작업 후 BuildContext 접근 시 위젯이 언마운트된 상태일 수 있음. 이는 앱 크래시를 유발할 수 있는 심각한 버그입니다.
  - **변경 전**: `_showError()`에서 직접 ScaffoldMessenger 접근
  - **변경 후**: `if (mounted)` 체크 후 ScaffoldMessenger 접근

## 발견된 개선 사항 (권고)

### 1. 중복 코드 패턴 (루틴 화면의 카테고리 맵 생성)
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/routine_screen.dart`
- **라인**: 22-26, 80-84
- **이슈**: 카테고리 맵 생성 로직이 중복됨 (build()와 FAB onPressed에서)
- **권고**: 메서드로 추출하거나 상단에서 한 번만 정의하여 재사용

### 2. WeeklyPlanScreen의 상태 초기화 로직
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/weekly_plan_screen.dart`
- **라인**: 36-46
- **이슈**: `_initFromPlan()` 메서드가 build() 중에 호출되어 상태 변경. 이는 렌더링 중 상태 변경이 발생하는 패턴입니다.
- **권고**: initState 또는 didChangeDependencies에서 한 번만 초기화하도록 리팩토링하는 것이 더 안정적

### 3. Key 생성의 일관성
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/weekly_plan_screen.dart`
- **라인**: 246
- **이슈**: `key: ValueKey(_goals[index] + index.toString())` - 리스트 항목 키로 index 포함하면 재정렬 시 문제 가능
- **권고**: UUID 또는 고유 ID 기반 키 사용, 또는 ValueKey로 오브젝트 자체 사용

### 4. 카테고리 선택 UI의 경계선 처리
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/routine_screen.dart`
- **라인**: 373
- **이슈**: "미지정" 칩에서 side property가 없음 (line 373)
- **권고**: 선택/미선택 상태의 일관성 있는 경계선 처리

### 5. 스트림 vs Future 제공자 혼용
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/providers/category_provider.dart`, `routine_provider.dart`
- **라인**: 14, 12
- **이슈**: `categoriesProvider`는 StreamProvider, `timeboxBlocksProvider`는 FutureProvider로 제공 방식 다름
- **권고**: 일관된 제공 방식 선택 (스트림 기반이 실시간 업데이트에 더 적합)

### 6. 매직 넘버 상수화
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/timebox_screen.dart`
- **라인**: 134
- **이슈**: `startMinute: 540` (09:00)이 하드코딩됨
- **권고**: `AppConstants.defaultStartMinute` 같은 상수로 정의하여 재사용

### 7. 빈 함수 호출 체크
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/presentation/screens/routine_screen.dart`
- **라인**: 79
- **이슈**: FAB의 onPressed에서 빈 categoryMap으로 `_showDialog` 호출 가능
- **권고**: null 체크 또는 실패 시나리오 처리

### 8. 미사용 임포트 및 라우트 정의
- **파일**: `/Users/isang-yong/Projects/timebox_planner/lib/app.dart`
- **라인**: 5-8
- **이슈**: 선언된 라우트들이 실제로 사용되지 않고, 네비게이션은 직접 Screen 클래스 호출로 처리
- **권고**: 불필요한 임포트/라우트 제거 또는 일관된 네비게이션 방식 선택

## 전반적 평가

### 강점
1. **Flutter/Dart 컨벤션 준수**: lowerCamelCase, UpperCamelCase, snake_case 네이밍이 적절하게 적용됨
2. **const 생성자 활용**: 대부분의 위젯이 const 생성자로 선언되어 불필요한 rebuild 방지
3. **mounted 체크**: 대부분의 async 작업에서 mounted 체크로 BuildContext 안전성 확보
4. **상태 관리**: Riverpod을 활용한 명확한 state management 구조
5. **에러 처리**: try-catch 블록으로 기본적인 에러 처리 구현
6. **위젯 분리**: 기능별/레이어별 명확한 분리로 코드 가독성 우수

### 개선 필요 영역
1. **중복 코드**: 카테고리 맵 생성 로직이 여러 곳에서 반복됨
2. **상태 초기화 타이밍**: build() 중 상태 변경이 발생하는 패턴
3. **Key 생성 방식**: ReorderableListView의 키 생성이 index 의존적
4. **일관성**: 제공자 타입(Stream vs Future), 네비게이션 방식의 혼용

### 코드 품질 지표
- **lint 경고**: 0건 ✓
- **BuildContext async 갭**: 1건 수정 ✓
- **const 생성자**: 적절히 활용 ✓
- **mounted 체크**: 대부분 구현, 1건 누락 수정 ✓
- **파일 크기**: 모든 파일이 300줄 이하로 적절 ✓

## 결론

전반적으로 코드 품질이 **우수**합니다. Flutter 모범 사례를 잘 따르고 있으며, 특히 State Management와 에러 처리가 견고합니다.

**수정 완료**한 BuildContext async 갭 문제(timebox_screen.dart의 _showError)를 통해 런타임 크래시 위험을 제거했으며, 현재 `flutter analyze` 결과는 **No issues found**입니다.

권고사항들은 향후 기능 추가나 리팩토링 시 개선하면 코드 유지보수성과 일관성을 더욱 향상시킬 수 있습니다.
