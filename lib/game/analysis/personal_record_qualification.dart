import '../domain/shot_input.dart';
import '../persistence/progress_store.dart';

Set<PersonalRecordKind> personalRecordsForClear({
  required bool optionalChallengeAchievedWithoutGuard,
  required Iterable<ShotAssistKind> assistKinds,
  required bool islandSupportUsed,
}) {
  final assists = assistKinds.toList(growable: false);
  return Set.unmodifiable({
    if (optionalChallengeAchievedWithoutGuard)
      PersonalRecordKind.gimmickMastery,
    if (assists.isNotEmpty &&
        assists.every((kind) => kind == ShotAssistKind.none))
      PersonalRecordKind.noAssistClear,
    if (!islandSupportUsed) PersonalRecordKind.noIslandSupportClear,
  });
}
