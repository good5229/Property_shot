import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/play_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  PlayTelemetryContext context() => PlayTelemetryContext(
    stageIndex: 0,
    stageId: 'stage_heavy',
    patternId: 'stage_heavy_a',
    seed: 42,
    resolverVersion: '판정기-1',
    rewardState: PlayTelemetryRewardState(
      candidateIds: const ['무거운 시작'],
      selectedId: '무거운 시작',
      acquiredIds: const ['무거운 시작'],
      cloneCoreCount: 1,
    ),
  );

  test('로컬 플레이 계측은 개인정보 없이 JSON과 CSV로 내보낼 수 있다', () {
    final telemetry = LocalPlayTelemetry();
    telemetry.record(
      '발사',
      stage: 0,
      attempt: 1,
      action: '이전',
      trait: '무거움',
      angle: -1.2,
      power: 0.8,
      resultCode: 'stage_cleared',
      routeTag: 'recommended',
    );
    telemetry.record('충돌', stage: 0, target: 'wall', result: '반사');

    expect(telemetry.events, hasLength(2));
    expect(telemetry.exportJson(), contains('무거움'));
    expect(telemetry.events.first['event_code'], 'shot_fired');
    expect(telemetry.events.first['session_id'], isNotEmpty);
    expect(telemetry.events.first['build_id'], 'property-shot-dev');
    expect(telemetry.events.first['stage_id'], 'stage_heavy');
    expect(telemetry.events.first['result_code'], 'stage_cleared');
    expect(telemetry.events.first['route_tag'], 'recommended');
    expect(telemetry.exportJson(), isNot(contains('사용자')));
    expect(telemetry.exportCsv(), startsWith('시간,유형,단계'));
    expect(telemetry.exportCsv(), contains('event_code'));
    expect(
      telemetry.exportCsv(),
      contains('단계,stage_id,시도,행동,속성,각도,힘,대상,결과,result_code,route_tag'),
    );
    expect(telemetry.exportCsv(), contains('발사'));
  });

  test('현재 세션 내보내기는 절대 시각과 세션 식별자를 제거하고 링크를 만들지 않는다', () async {
    SharedPreferences.setMockInitialValues({});
    final telemetry = LocalPlayTelemetry(sessionId: 'private-session');
    telemetry.record('단계 시작', stage: 0);
    telemetry.record('발사', stage: 0, angle: 1.2, power: 0.6);

    final exported = await telemetry.exportPrivacySafeSessionJson();

    expect(exported, contains('property-shot-local-session/v1'));
    expect(exported, contains('"event_count": 2'));
    expect(exported, contains('"external_link_created": false'));
    expect(exported, isNot(contains('private-session')));
    final decoded = jsonDecode(exported) as Map<String, Object?>;
    final events = (decoded['events'] as List).cast<Map<String, Object?>>();
    expect(events.every((event) => !event.containsKey('시간')), isTrue);
    expect(events.every((event) => event['session_elapsed_ms'] is int), isTrue);
    expect(exported, isNot(contains('http')));
    expect(exported, contains('"순서": 1'));
  });

  test('세션과 물리 필드를 내부 코드로 내보낸다', () {
    final telemetry = LocalPlayTelemetry(sessionId: '검증 세션');
    telemetry.sessionStart(stage: 0, experimentVariant: 'guided');
    telemetry.record(
      '충돌',
      stage: 0,
      eventCode: 'collision_resolved',
      objectId: 'wall_top',
      objectType: 'wall',
      impulse: 0.7,
      isReplay: true,
    );
    telemetry.sessionEnd(stage: 0);

    expect(telemetry.events.map((event) => event['event_code']), [
      'session_start',
      'collision_resolved',
      'session_end',
    ]);
    expect(telemetry.events.first['결과'], 'guided');
    expect(telemetry.exportJson(), contains('wall_top'));
    expect(telemetry.exportJson(), contains('is_replay'));
  });

  test('최종 실험 계획의 필수 이벤트 코드가 한글 유형과 함께 유지된다', () {
    final telemetry = LocalPlayTelemetry(sessionId: '이벤트 검증');
    const types = {
      '단계 시작': 'stage_enter',
      '속성 확인': 'object_inspected',
      '속성 이전 열기': 'attribute_transfer_opened',
      '속성 이전': 'attribute_transferred',
      '속성 복사': 'attribute_copied',
      '속성 행동 취소': 'attribute_action_cancelled',
      '조준 시작': 'aim_started',
      '조준 방향 변경': 'aim_direction_changed',
      '충전 시작': 'charge_started',
      '충전 종료': 'charge_released',
      '발사': 'shot_fired',
      '충돌': 'collision_resolved',
      '연쇄 이동': 'object_started_moving',
      '물체 정지': 'object_stopped',
      '속성 소모': 'attribute_consumed',
      '스위치 작동': 'switch_activated',
      '문 열림': 'door_opened',
      '풍선 변형': 'balloon_deformed',
      '풍선 터짐': 'balloon_popped',
      '점착 정지': 'ball_stuck',
      '홀 진입': 'ball_entered_hole',
      '클리어': 'stage_cleared',
      '실패': 'stage_failed_or_reset',
      '힌트 노출': 'hint_exposed',
      '재시도': 'retry_pressed',
      '단계 종료': 'stage_exit',
    };

    for (final type in types.keys) {
      telemetry.record(type, stage: 0);
    }

    expect(telemetry.events.map((event) => event['event_code']), types.values);
  });

  test('총괄 계약의 타입 이벤트 32개를 빠짐없이 안정 코드와 한글 표시명으로 정의한다', () {
    const expectedCodes = {
      'run_started',
      'stage_pattern_drawn',
      'stage_entered',
      'property_popup_opened',
      'property_transferred',
      'property_copied',
      'aim_started',
      'charge_stage_changed',
      'charge_cancelled',
      'shot_released',
      'collision_chain_completed',
      'reward_offered',
      'reward_selected',
      'reward_used',
      'optional_challenge_completed',
      'stage_cleared',
      'stage_retried',
      'stage_abandoned',
      'replay_viewed',
      'daily_challenge_started',
      'run_completed',
      'hint_reward_offered',
      'hint_reward_selected',
      'hint_available',
      'hint_opened',
      'hint_level_opened',
      'key_spawned',
      'key_collected',
      'key_ignored',
      'demo_direct_clear_detected',
      'power_gauge_charge_started',
      'power_gauge_cancelled',
    };

    expect(PlayTelemetryEventType.values, hasLength(32));
    expect(
      PlayTelemetryEventType.values.map((type) => type.code).toSet(),
      expectedCodes,
    );
    expect(
      PlayTelemetryEventType.values.every(
        (type) =>
            type.displayName.isNotEmpty &&
            !RegExp(r'[A-Za-z]').hasMatch(type.displayName),
      ),
      isTrue,
    );
  });

  test('보상 사용은 선택·사용 거리와 발동 방식을 기록한다', () {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.rewardUsed,
        context: context(),
        result: PlayTelemetryResult.continued,
        rewardUse: PlayTelemetryRewardUsePayload(
          rewardId: 'first_impact_guide_once',
          useKey: 'stage_bouncy:1:첫충돌',
          trigger: PlayTelemetryRewardTrigger.automatic,
          stageScoped: false,
          selectionRecordId:
              'run_reward:stage_heavy:42:first_impact_guide_once',
          stageDistance: 1,
        ),
      ),
    );

    final event = telemetry.events.single;
    expect(event['event_code'], 'reward_used');
    expect(event['reward_used_id'], 'first_impact_guide_once');
    expect(event['reward_use_trigger'], 'automatic');
    expect(event['reward_use_stage_distance'], 1);
    expect(telemetry.exportCsv(), contains('reward_selection_record_id'));
    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.rewardUsed,
        context: context(),
      ),
      throwsArgumentError,
    );
  });

  test('힌트·열쇠·시연 판정 보조 payload를 닫힌 타입으로 JSON과 CSV에 기록한다', () {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    final stageOutcome = PlayTelemetryStageOutcomePayload(
      keyCollected: true,
      directClear: false,
      hintUsedBeforeClear: true,
      failureCountBeforeHint: 2,
      failureCountAfterHint: 1,
      gimmickTypes: const ['rotating_reflector', 'bumper'],
      effectiveChainScore: 4,
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.hintOpened,
        context: context(),
        hint: PlayTelemetryHintPayload(
          source: PlayTelemetryHintSource.stageKey,
          level: PlayTelemetryHintLevel.two,
          openedCount: 1,
          failureCountBeforeOpen: 2,
          clearedAfterOpen: false,
        ),
      ),
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.keyCollected,
        context: context(),
        key: PlayTelemetryKeyPayload(
          keyId: 'rotating_01_hint_key',
          shotId: 3,
          collected: true,
          shotsUntilCollected: 3,
        ),
      ),
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.stageCleared,
        context: context(),
        result: PlayTelemetryResult.cleared,
        stageOutcome: stageOutcome,
      ),
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.demoDirectClearDetected,
        context: context(),
        stageOutcome: PlayTelemetryStageOutcomePayload(
          keyCollected: false,
          directClear: true,
          hintUsedBeforeClear: false,
          failureCountBeforeHint: 0,
          failureCountAfterHint: 0,
          effectiveChainScore: 0,
        ),
      ),
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.powerGaugeCancelled,
        context: context(),
        powerGauge: PlayTelemetryPowerGaugePayload(
          chargeStage: 4,
          power: 0.92,
          cancelled: true,
        ),
      ),
    );

    final hintEvent = telemetry.events[0];
    final keyEvent = telemetry.events[1];
    final clearEvent = telemetry.events[2];
    expect(hintEvent['hint_source'], 'stage_key');
    expect(hintEvent['hint_level'], 2);
    expect(hintEvent['hint_failure_count_before_open'], 2);
    expect(keyEvent['key_id'], 'rotating_01_hint_key');
    expect(keyEvent['key_shot_id'], 3);
    expect(keyEvent['key_shots_until_collected'], 3);
    expect(clearEvent['key_collected_before_clear'], isTrue);
    expect(clearEvent['hint_used_before_clear'], isTrue);
    expect(clearEvent['gimmick_types'], ['rotating_reflector', 'bumper']);
    expect(clearEvent['effective_chain_score'], 4);
    expect(telemetry.events[3]['direct_clear'], isTrue);
    expect(telemetry.events[4]['power_gauge_cancelled'], isTrue);
    expect(telemetry.exportJson(), contains('rotating_reflector'));
    expect(telemetry.exportCsv(), contains('hint_source'));
    expect(telemetry.exportCsv(), contains('key_shots_until_collected'));
    expect(telemetry.exportCsv(), contains('effective_chain_score'));
  });

  test('파워 게이지 payload는 다섯 상태 밖의 단계를 거부한다', () {
    expect(
      () => PlayTelemetryPowerGaugePayload(
        chargeStage: 5,
        power: 1,
        cancelled: true,
      ),
      throwsArgumentError,
    );
  });

  test('단계 클리어 typed event는 결과와 전체 단계 outcome을 모두 요구한다', () {
    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.stageCleared,
        context: context(),
        result: PlayTelemetryResult.cleared,
      ),
      throwsArgumentError,
    );
  });

  test('힌트·열쇠·게이지 이벤트는 타입에 맞는 payload만 허용한다', () {
    final hint = PlayTelemetryHintPayload(
      source: PlayTelemetryHintSource.clearReward,
      level: PlayTelemetryHintLevel.one,
    );
    final collectedKey = PlayTelemetryKeyPayload(
      keyId: 'hint_key',
      shotId: 1,
      collected: true,
      shotsUntilCollected: 1,
    );

    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.hintOpened,
        context: context(),
      ),
      throwsArgumentError,
    );
    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.hintRewardSelected,
        context: context(),
        hint: PlayTelemetryHintPayload(
          source: PlayTelemetryHintSource.stageKey,
          level: PlayTelemetryHintLevel.one,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.keySpawned,
        context: context(),
        key: collectedKey,
      ),
      throwsArgumentError,
    );
    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.demoDirectClearDetected,
        context: context(),
        stageOutcome: PlayTelemetryStageOutcomePayload(
          keyCollected: false,
          directClear: false,
          hintUsedBeforeClear: false,
          failureCountBeforeHint: 0,
          failureCountAfterHint: 0,
          effectiveChainScore: 0,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.powerGaugeChargeStarted,
        context: context(),
        powerGauge: PlayTelemetryPowerGaugePayload(
          chargeStage: 1,
          power: 0.3,
          cancelled: true,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => PlayTelemetryKeyPayload(
        keyId: 'hint_key',
        shotId: 1,
        collected: false,
        shotsUntilCollected: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => PlayTelemetryPowerGaugePayload(
        chargeStage: -1,
        power: 0.3,
        cancelled: false,
      ),
      throwsArgumentError,
    );
    expect(hint.source, PlayTelemetryHintSource.clearReward);
  });

  test('타입 이벤트는 공통 문맥과 필수 샷 지표를 JSON과 CSV에 직렬화한다', () {
    final telemetry = LocalPlayTelemetry(
      sessionId: '익명 세션',
      persistLocally: false,
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.collisionChainCompleted,
        context: context(),
        shot: PlayTelemetryShotPayload(
          shotId: 3,
          angle: -1.2,
          power: 0.85,
          ballTraits: const ['무거움'],
          causalChain: const ['충돌-1', '반사-2', '홀-3'],
          causalDepth: 2,
          effectiveChainLength: 3,
          distinctObjectTypeCount: 2,
          distinctObjectCount: 3,
          wallUseCount: 1,
          ballUseCount: 1,
          objectUseCount: 1,
          scoreDamped: true,
          nearestHoleDistance: 0.25,
          frameDurationMs: 16.7,
          inputLatencyMs: 8.3,
          rawAngle: -1.23,
          rawPower: 0.843,
          assistKind: 'targetSnap',
          assistTargetId: 'wall_1',
          holeForgivenessRadius: 6,
          result: PlayTelemetryResult.cleared,
        ),
      ),
    );

    final event = telemetry.events.single;
    expect(event['event_code'], 'collision_chain_completed');
    expect(event['유형'], '충돌 연쇄 완료');
    expect(event['pattern_id'], 'stage_heavy_a');
    expect(event['seed'], 42);
    expect(event['resolver_version'], '판정기-1');
    expect(event['reward_selected_id'], '무거운 시작');
    expect(event['causal_chain'], ['충돌-1', '반사-2', '홀-3']);
    expect(event['causal_depth'], 2);
    expect(event['effective_chain_length'], 3);
    expect(event['distinct_object_type_count'], 2);
    expect(event['distinct_object_count'], 3);
    expect(event['wall_use_count'], 1);
    expect(event['ball_use_count'], 1);
    expect(event['object_use_count'], 1);
    expect(event['score_damped'], isTrue);
    expect(event['raw_angle'], -1.23);
    expect(event['raw_power'], 0.843);
    expect(event['intent_assist_kind'], 'targetSnap');
    expect(event['intent_assist_target_id'], 'wall_1');
    expect(event['hole_forgiveness_radius'], 6);
    expect(event['nearest_hole_distance'], 0.25);
    expect(event['frame_duration_ms'], 16.7);
    expect(event['input_latency_ms'], 8.3);
    expect(event['result_code'], 'cleared');
    expect(telemetry.exportJson(), contains('stage_heavy_a'));
    expect(telemetry.exportCsv(), contains('pattern_id'));
    expect(telemetry.exportCsv(), contains('collision_chain_completed'));
  });

  test('입력 지연 보고서는 비리플레이 20표본의 최근접 순위 p95를 판정한다', () {
    final events = <Map<String, Object?>>[
      for (var index = 1; index <= 20; index++)
        {
          'event_code': 'shot_released',
          'is_replay': false,
          'input_latency_ms': index.toDouble(),
        },
      {
        'event_code': 'shot_released',
        'is_replay': true,
        'input_latency_ms': 900.0,
      },
      {'event_code': 'shot_released', 'input_latency_ms': '잘못된 값'},
      {'event_code': 'stage_cleared', 'input_latency_ms': 900.0},
    ];

    final report = InputLatencyReport.fromEvents(events);

    expect(report.sampleCount, 20);
    expect(report.replaySampleCount, 1);
    expect(report.invalidSampleCount, 1);
    expect(report.p95Milliseconds, 19);
    expect(report.maximumMilliseconds, 20);
    expect(report.status, InputLatencyGateStatus.passed);
    expect(report.summaryLabel, '입력 지연 p95 19.0밀리초 · 기준 통과');
  });

  test('입력 지연 보고서는 표본 부족과 50밀리초 초과를 통과로 오인하지 않는다', () {
    final insufficient = InputLatencyReport.fromEvents([
      for (var index = 0; index < 19; index++)
        {'event_code': 'shot_released', 'input_latency_ms': 3.0},
    ]);
    final failed = InputLatencyReport.fromEvents([
      for (var index = 0; index < 18; index++)
        {'event_code': 'shot_released', 'input_latency_ms': 4.0},
      {'event_code': 'shot_released', 'input_latency_ms': 51.0},
      {'event_code': 'shot_released', 'input_latency_ms': 70.0},
    ]);

    expect(insufficient.status, InputLatencyGateStatus.insufficientSamples);
    expect(insufficient.summaryLabel, '입력 지연 표본 19/20개 · p95 3.0밀리초');
    expect(failed.p95Milliseconds, 51);
    expect(failed.status, InputLatencyGateStatus.failed);
    expect(failed.toJson()['판정'], '기준 미통과');
  });

  test('타입 payload는 비유한 수와 잘못된 범위 및 빈 식별자를 거부한다', () {
    PlayTelemetryShotPayload validShot({
      double angle = 0,
      double power = 0.5,
      double nearestHoleDistance = 1,
      double frameDurationMs = 16,
      double inputLatencyMs = 4,
      int causalDepth = 1,
      int effectiveChainLength = 1,
    }) => PlayTelemetryShotPayload(
      shotId: 1,
      angle: angle,
      power: power,
      causalChain: const ['충돌-1'],
      causalDepth: causalDepth,
      effectiveChainLength: effectiveChainLength,
      distinctObjectTypeCount: 1,
      distinctObjectCount: 1,
      wallUseCount: 0,
      ballUseCount: 1,
      objectUseCount: 0,
      scoreDamped: false,
      nearestHoleDistance: nearestHoleDistance,
      frameDurationMs: frameDurationMs,
      inputLatencyMs: inputLatencyMs,
      result: PlayTelemetryResult.continued,
    );

    expect(() => validShot(angle: double.nan), throwsArgumentError);
    expect(() => validShot(power: 1.01), throwsArgumentError);
    expect(
      () => validShot(nearestHoleDistance: double.infinity),
      throwsArgumentError,
    );
    expect(() => validShot(frameDurationMs: -1), throwsArgumentError);
    expect(() => validShot(inputLatencyMs: double.nan), throwsArgumentError);
    expect(() => validShot(causalDepth: -1), throwsArgumentError);
    expect(() => validShot(effectiveChainLength: -1), throwsArgumentError);
    expect(
      () => PlayTelemetryShotPayload(
        shotId: 1,
        angle: 0,
        power: 0.5,
        causalDepth: 0,
        effectiveChainLength: 0,
        distinctObjectTypeCount: 0,
        distinctObjectCount: 0,
        wallUseCount: 0,
        ballUseCount: 0,
        objectUseCount: 0,
        scoreDamped: false,
        nearestHoleDistance: 0,
        frameDurationMs: 16,
        inputLatencyMs: 4,
        rawPower: double.nan,
        holeForgivenessRadius: 17,
        result: PlayTelemetryResult.continued,
      ),
      throwsArgumentError,
    );
    expect(
      () => PlayTelemetryContext(
        stageIndex: 0,
        stageId: '',
        patternId: '패턴',
        seed: 1,
        resolverVersion: '1',
        rewardState: PlayTelemetryRewardState(),
      ),
      throwsArgumentError,
    );
    for (final invalidSeed in [-1, 0x100000000]) {
      expect(
        () => PlayTelemetryContext(
          stageIndex: 0,
          stageId: '단계',
          patternId: '패턴',
          seed: invalidSeed,
          resolverVersion: '1',
          rewardState: PlayTelemetryRewardState(),
        ),
        throwsArgumentError,
      );
    }
  });

  test('타입 스키마와 저장 결과는 개인정보 필드를 수집하지 않는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final telemetry = LocalPlayTelemetry(sessionId: '무작위 세션');
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.runStarted,
        context: context(),
        result: PlayTelemetryResult.continued,
      ),
    );
    await telemetry.flush();

    const forbiddenKeys = {
      'name',
      'email',
      'phone',
      'address',
      'user_id',
      'device_id',
      'advertising_id',
      '이름',
      '이메일',
      '전화번호',
      '주소',
    };
    final stored = (await telemetry.loadPersisted()).single;
    expect(stored.keys.toSet().intersection(forbiddenKeys), isEmpty);
  });

  test('난이도와 조준 보조 사용 여부를 공통 문맥에 기록한다', () {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    final normalContext = context();
    expect(normalContext.difficulty, PlayTelemetryDifficulty.normal);
    expect(normalContext.aimAssistEnabled, isFalse);
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.aimStarted,
        context: context().copyWith(difficulty: PlayTelemetryDifficulty.easy),
      ),
    );

    expect(telemetry.events.single['difficulty_mode'], 'easy');
    expect(telemetry.events.single['aim_assist_enabled'], isTrue);
  });

  test('기존 CSV 열은 같은 순서의 접두부로 유지된다', () {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.shotReleased,
        context: context(),
      ),
    );

    const legacyHeader =
        '시간,유형,단계,stage_id,시도,행동,속성,각도,힘,대상,결과,'
        'result_code,route_tag,event_code,session_id,build_id,shot_id,'
        'object_id,object_type,contact_id,attribute_before,attribute_after,'
        'position,velocity,collision_normal,speed,speed_before,speed_after,'
        'reference_speed,mass,impulse,is_replay,fps_bucket,elapsed_ms';
    expect(telemetry.exportCsv(), startsWith('$legacyHeader,'));
  });

  test('구형 저장 JSON을 그대로 복원하고 새 이벤트와 함께 저장 상한을 지킨다', () async {
    SharedPreferences.setMockInitialValues({
      LocalPlayTelemetryStore.storageKey:
          '[{"시간":"과거","유형":"발사","단계":1,"event_code":"shot_fired"}]',
    });
    final store = LocalPlayTelemetryStore(maxEvents: 2);
    final telemetry = LocalPlayTelemetry(store: store);

    expect((await store.load()).single['event_code'], 'shot_fired');
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.stageEntered,
        context: context(),
      ),
    );
    telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.aimStarted,
        context: context(),
      ),
    );
    await telemetry.flush();

    final restored = await store.load();
    expect(restored, hasLength(2));
    expect(restored.map((event) => event['event_code']), [
      'stage_entered',
      'aim_started',
    ]);
  });

  test('장시간 플레이의 메모리 이벤트도 고정 상한을 유지한다', () {
    final telemetry = LocalPlayTelemetry(
      persistLocally: false,
      maxMemoryEvents: 3,
    );
    for (var index = 0; index < 5; index++) {
      telemetry.record('조준 방향 변경', stage: 0, attempt: index);
    }

    expect(telemetry.events, hasLength(3));
    expect(telemetry.events.map((event) => event['시도']), [2, 3, 4]);
  });

  test('플레이 계측은 개인정보 없이 로컬 저장소에 보관되고 복원된다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final telemetry = LocalPlayTelemetry(
      sessionId: '저장 검증',
      store: LocalPlayTelemetryStore(maxEvents: 2),
    );

    telemetry.record('발사', stage: 0, eventCode: 'shot_fired');
    telemetry.record('충돌', stage: 0, eventCode: 'collision_resolved');
    telemetry.record('클리어', stage: 0, eventCode: 'stage_cleared');
    await telemetry.flush();

    final restored = await telemetry.loadPersisted();
    expect(restored, hasLength(2));
    expect(restored.map((event) => event['event_code']), [
      'collision_resolved',
      'stage_cleared',
    ]);
    expect(restored.every((event) => !event.containsKey('사용자')), isTrue);

    await telemetry.clearPersisted();
    expect(await telemetry.loadPersisted(), isEmpty);
  });

  test('동시에 기록된 로컬 계측 이벤트의 순서를 보존한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalPlayTelemetryStore();
    final telemetry = LocalPlayTelemetry(store: store);

    telemetry.record('첫 이벤트', stage: 0);
    telemetry.record('둘째 이벤트', stage: 0);
    telemetry.record('셋째 이벤트', stage: 0);
    await telemetry.flush();

    final restored = await store.load();
    expect(restored.map((event) => event['유형']), ['첫 이벤트', '둘째 이벤트', '셋째 이벤트']);
  });

  test('조회 시 대기 중인 이벤트를 먼저 묶음 저장한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final telemetry = LocalPlayTelemetry();

    telemetry.record('충돌', stage: 0, eventCode: 'collision_resolved');

    final restored = await telemetry.loadPersisted();
    expect(restored, hasLength(1));
    expect(restored.single['event_code'], 'collision_resolved');
  });
}
