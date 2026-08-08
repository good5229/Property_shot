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

  test('총괄 계약의 타입 이벤트 20개를 빠짐없이 안정 코드와 한글 표시명으로 정의한다', () {
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
      'optional_challenge_completed',
      'stage_cleared',
      'stage_retried',
      'stage_abandoned',
      'replay_viewed',
      'daily_challenge_started',
      'run_completed',
    };

    expect(PlayTelemetryEventType.values, hasLength(20));
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
    expect(event['nearest_hole_distance'], 0.25);
    expect(event['frame_duration_ms'], 16.7);
    expect(event['input_latency_ms'], 8.3);
    expect(event['result_code'], 'cleared');
    expect(telemetry.exportJson(), contains('stage_heavy_a'));
    expect(telemetry.exportCsv(), contains('pattern_id'));
    expect(telemetry.exportCsv(), contains('collision_chain_completed'));
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
