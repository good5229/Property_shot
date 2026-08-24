import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/personal_record_qualification.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/persistence/progress_store.dart';

void main() {
  test('보호 보상으로 보전된 선택 도전은 기믹 숙련 기록을 주지 않는다', () {
    final records = personalRecordsForClear(
      optionalChallengeAchievedWithoutGuard: false,
      assistKinds: const [ShotAssistKind.none],
      islandSupportUsed: false,
    );

    expect(records, isNot(contains(PersonalRecordKind.gimmickMastery)));
    expect(records, contains(PersonalRecordKind.noAssistClear));
    expect(records, contains(PersonalRecordKind.noIslandSupportClear));
  });

  test('한 번이라도 보정이나 집중 지원을 쓰면 해당 기록을 주지 않는다', () {
    final records = personalRecordsForClear(
      optionalChallengeAchievedWithoutGuard: true,
      assistKinds: const [ShotAssistKind.none, ShotAssistKind.targetSnap],
      islandSupportUsed: true,
    );

    expect(records, {PersonalRecordKind.gimmickMastery});
  });

  test('발사 기록이 없는 비정상 완료는 무보정 기록을 주지 않는다', () {
    final records = personalRecordsForClear(
      optionalChallengeAchievedWithoutGuard: false,
      assistKinds: const [],
      islandSupportUsed: false,
    );

    expect(records, isNot(contains(PersonalRecordKind.noAssistClear)));
  });
}
