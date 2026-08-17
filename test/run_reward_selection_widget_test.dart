import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/ui/game_screen.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  testWidgets('보상을 고르기 전에는 다음과 기록 재도전을 사용할 수 없다', (tester) async {
    await tester.pumpWidget(_popupApp());
    await tester.pumpAndSettle();

    expect(find.text('런 보상 하나 선택'), findsOneWidget);
    expect(find.byKey(const Key('run_reward_selection')), findsOneWidget);
    for (final reward in initialRunRewards.take(3)) {
      expect(find.byKey(Key('run_reward_usage_${reward.id}')), findsOneWidget);
    }
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('next_stage_button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('retry_stage_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('저장된 보상 선택은 완료 표시와 다음 행동을 연다', (tester) async {
    String? selectedId;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _popupApp(
          selectedRewardId: selectedId,
          onRewardSelected: (id) => setState(() => selectedId = id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final target = find.byKey(Key('run_reward_${initialRunRewards.first.id}'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();

    expect(selectedId, initialRunRewards.first.id);
    expect(find.text('런 보상 선택 완료'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('next_stage_button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('보상 저장 실패는 같은 세 후보를 유지하고 다시 선택할 수 있다', (tester) async {
    final level = levels.first;
    final state = level
        .createState(0, productRules: true)
        .copyWith(phase: GamePhase.success, shotCount: 2);
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: state,
          levelOverride: level,
          loadGameAssets: false,
          initialRewardCandidates: initialRunRewards.take(3).toList(),
          onRewardSelected: (id) async {
            attempts++;
            throw StateError('보상 저장 실패 주입');
          },
        ),
      ),
    );
    await tester.pump();

    final target = find.byKey(Key('run_reward_${initialRunRewards.first.id}'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();

    expect(attempts, 1);
    expect(find.byKey(const Key('run_reward_error')), findsOneWidget);
    expect(find.text('보상을 저장하지 못했습니다. 다시 선택해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('run_reward_selection')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(target).onPressed, isNotNull);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('next_stage_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('런 보상 10종은 서로 다른 무료 Material 아이콘을 사용한다', (tester) async {
    await tester.pumpWidget(_popupApp(rewards: initialRunRewards));
    await tester.pumpAndSettle();

    final icons = <IconData>{};
    for (final reward in initialRunRewards) {
      final iconRoot = find.byKey(Key('run_reward_icon_${reward.id}'));
      expect(iconRoot, findsOneWidget);
      final icon = tester.widget<Icon>(
        find.descendant(of: iconRoot, matching: find.byType(Icon)).first,
      );
      expect(icon.icon, isNotNull);
      icons.add(icon.icon!);
    }
    expect(icons, hasLength(initialRunRewards.length));
  });

  testWidgets('320x568에서는 다음 스테이지 팁 보상이 첫 viewport에 보인다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final hintReward = initialRunRewards.firstWhere(
      (reward) => reward.id == runRewardNextStageHintAccessId,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('run_reward_compact_hint_golden'),
        child: _popupApp(rewards: [hintReward, ...initialRunRewards.take(2)]),
      ),
    );
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.byKey(const Key('clear_panel')));
    final selection = tester.getRect(
      find.byKey(const Key('run_reward_selection')),
    );
    final hintChoice = tester.getRect(
      find.byKey(Key('run_reward_${hintReward.id}')),
    );
    expect(selection.top, greaterThanOrEqualTo(panel.top));
    expect(selection.top, lessThan(panel.bottom - 96));
    expect(hintChoice.top, lessThan(panel.bottom - 48));
    expect(find.byKey(const Key('clear_leaderboard')), findsNothing);
    await expectLater(
      find.byKey(const Key('run_reward_compact_hint_golden')),
      matchesGoldenFile('goldens/run_reward_320x568_hint_first.png'),
    );
  });

  for (final fixture in const [
    (
      name: '320x700',
      width: 320.0,
      height: 700.0,
      textScale: 1.0,
      rewardOffset: 2,
    ),
    (
      name: '390x844',
      width: 390.0,
      height: 844.0,
      textScale: 1.0,
      rewardOffset: 0,
    ),
    (
      name: '390x844_large_text',
      width: 390.0,
      height: 844.0,
      textScale: 1.3,
      rewardOffset: 3,
    ),
    (
      name: '390x844_rewards_4_6',
      width: 390.0,
      height: 844.0,
      textScale: 1.0,
      rewardOffset: 3,
    ),
    (
      name: '390x844_rewards_6_8',
      width: 390.0,
      height: 844.0,
      textScale: 1.0,
      rewardOffset: 5,
    ),
    (
      name: '768x1024',
      width: 768.0,
      height: 1024.0,
      textScale: 1.0,
      rewardOffset: 5,
    ),
  ]) {
    testWidgets('런 보상 선택 팝업 Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('run_reward_golden'),
          child: _popupApp(
            textScale: fixture.textScale,
            rewards: initialRunRewards
                .skip(fixture.rewardOffset)
                .take(3)
                .toList(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rewardSection = find.byKey(const Key('run_reward_selection'));
      await tester.ensureVisible(rewardSection);
      await tester.pump();
      await expectLater(
        find.byKey(const Key('run_reward_golden')),
        matchesGoldenFile('goldens/run_reward_${fixture.name}.png'),
      );
    });
  }
}

Widget _popupApp({
  String? selectedRewardId,
  ValueChanged<String>? onRewardSelected,
  double textScale = 1,
  List<RunReward>? rewards,
}) {
  final level = levels.first;
  final state = level
      .createState(0, productRules: true)
      .copyWith(phase: GamePhase.success, shotCount: 2);
  return MaterialApp(
    theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: ClearResultPopup(
        state: state,
        level: level,
        onNext: () {},
        onRetry: () {},
        isFinal: false,
        bonusAchieved: true,
        bestShot: 2,
        rewardCandidates: rewards ?? initialRunRewards.take(3).toList(),
        selectedRewardId: selectedRewardId,
        onRewardSelected: onRewardSelected,
      ),
    ),
  );
}
