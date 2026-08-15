import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/lab/physics_lab.dart';
import 'package:property_shot/game/lab/physics_lab_creator.dart';
import 'package:property_shot/ui/physics_lab_screen.dart';

void main() {
  String? clipboardText;
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, Object?>{'text': clipboardText};
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('허용된 모든 템플릿과 목표 위치는 보드 안의 안전한 배치를 만든다', () {
    const validator = PhysicsLabDraftValidator();
    for (final scenario in physicsLabScenarios) {
      for (final position in LabGoalPosition.values) {
        final draft = PhysicsLabDraft(
          baseScenarioId: scenario.id,
          goalPosition: position,
        );
        expect(
          validator.validate(draft),
          isNull,
          reason: '${scenario.id}/$position',
        );
        final built = validator.build(draft);
        final state = built.level.createState(built.linkedStageIndex);
        final hole = state.entities.singleWhere(
          (item) => item.type == EntityType.hole,
        );
        expect(hole.position, position.position);
        expect(state.activeBall.position, isNot(hole.position));
        expect(built.id, startsWith('custom_'));
      }
    }
  });

  test('공유 코드는 결정적으로 왕복하고 손상·미지원·과대 입력을 거부한다', () {
    const draft = PhysicsLabDraft(
      baseScenarioId: 'lab_bouncy_second_rebound_v1',
      goalPosition: LabGoalPosition.northwest,
    );
    final first = PhysicsLabShareCode.encode(draft);
    final second = PhysicsLabShareCode.encode(draft);
    expect(first, second);
    expect(first, startsWith(physicsLabSharePrefix));
    final decoded = PhysicsLabShareCode.decode(first);
    expect(decoded.baseScenarioId, draft.baseScenarioId);
    expect(decoded.goalPosition, draft.goalPosition);

    final replacement = first.endsWith('A') ? 'B' : 'A';
    expect(
      () => PhysicsLabShareCode.decode(
        '${first.substring(0, first.length - 1)}$replacement',
      ),
      throwsFormatException,
    );
    expect(() => PhysicsLabShareCode.decode('잘못된코드'), throwsFormatException);
    expect(
      () => PhysicsLabShareCode.decode(
        '속실1:${List<String>.filled(1100, 'A').join()}',
      ),
      throwsFormatException,
    );
    expect(
      const PhysicsLabDraftValidator().validate(
        const PhysicsLabDraft(
          baseScenarioId: 'unknown',
          goalPosition: LabGoalPosition.north,
        ),
      ),
      contains('알 수 없는'),
    );
  });

  testWidgets('모바일 편집기는 검증·공유·실행 흐름을 제공한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: PhysicsLabScreen(onBack: () {}, loadGameAssets: false),
      ),
    );
    await tester.tap(find.byKey(const Key('physics_lab_create_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('physics_lab_creator')), findsOneWidget);
    expect(find.text('안전 검사 통과'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.byKey(const Key('lab_copy_draft_button')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('lab_copy_draft_button')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('공유 코드를 복사했습니다.'), findsOneWidget);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    expect(clipboard?.text, startsWith(physicsLabSharePrefix));

    await tester.scrollUntilVisible(
      find.byKey(const Key('lab_play_draft_button')),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(
      find.byKey(const Key('lab_play_draft_button')).hitTestable(),
    );
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('물리 실험실: 나만의')), findsOneWidget);
    expect(find.byTooltip('실험 목록'), findsOneWidget);
  });

  testWidgets('나만의 실험 편집 화면 Golden 390x844', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: PhysicsLabScreen(onBack: () {}, loadGameAssets: false),
      ),
    );
    await tester.tap(find.byKey(const Key('physics_lab_create_button')));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('physics_lab_creator')),
      matchesGoldenFile('goldens/physics_lab_creator_390x844.png'),
    );
  });
}
