import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 배치 항목 유형
enum PendingItemType { brainDump, routine }

/// 배치 대기 중인 항목 정보
class PendingPlacement {
  final String itemId;
  final String title;
  final String? description;
  final PendingItemType type;
  final int? startMinute; // null = 시작 시간 미선택

  const PendingPlacement({
    required this.itemId,
    required this.title,
    this.description,
    required this.type,
    this.startMinute,
  });

  PendingPlacement withStartMinute(int m) => PendingPlacement(
        itemId: itemId,
        title: title,
        description: description,
        type: type,
        startMinute: m,
      );
}

/// 배치 모드 상태 Notifier
class PlacementNotifier extends StateNotifier<PendingPlacement?> {
  PlacementNotifier() : super(null);

  /// 배치 모드 시작 (브레인덤프 또는 루틴 항목 선택)
  void startPlacement({
    required String itemId,
    required String title,
    String? description,
    required PendingItemType type,
    int? initialStartMinute,
  }) {
    state = PendingPlacement(
      itemId: itemId,
      title: title,
      description: description,
      type: type,
      startMinute: initialStartMinute,
    );
  }

  /// 시작 시간 선택
  void setStartMinute(int minute) {
    if (state != null) {
      state = state!.withStartMinute(minute);
    }
  }

  /// 배치 모드 종료 (완료 또는 취소)
  void clearPlacement() {
    state = null;
  }
}

final placementProvider =
    StateNotifierProvider<PlacementNotifier, PendingPlacement?>(
  (ref) => PlacementNotifier(),
);
