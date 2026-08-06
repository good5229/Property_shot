import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

void main() {
  group('StagePatternValidator 기본 정책', () {
    test('정상 3패턴 스테이지를 통과시킨다', () {
      final report = StagePatternValidator().validate(_validStage());

      expect(report.isValid, isTrue);
      expect(report.issues, isEmpty);
    });

    test('기존 1~4단계는 레거시 개별 배치 검사에 통과한다', () {
      final validator = StagePatternValidator();

      for (final level in levels) {
        final report = validator.validateLegacyLevel(level);
        expect(report.isValid, isTrue, reason: '${level.id}: ${report.issues}');
      }
    });

    test('레거시 검사에서도 수치·배치 결함은 숨기지 않는다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            id: 'legacy',
            objects: [
              _hole(),
              _object('bad', EntityType.crate, const Vec2(10, 10)),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.hasCode(ValidationIssueCode.objectOutOfBounds), isTrue);
      expect(
        report.hasCode(ValidationIssueCode.patternCountOutOfRange),
        isFalse,
      );
      expect(
        report.hasCode(ValidationIssueCode.insufficientSolutionFamilies),
        isFalse,
      );
    });

    test('여러 스테이지의 입력 순서를 유지하고 반복 결과가 같다', () {
      final stages = [_validStage(id: 'z-stage'), _validStage(id: 'a-stage')];
      final validator = StagePatternValidator();

      final first = validator.validateStages(stages);
      final second = validator.validateStages(stages);

      expect(first.issues, isEmpty);
      expect(second.issues, isEmpty);
      expect(
        ValidationIssueCode.values.map((code) => code.schemaName).toSet(),
        hasLength(ValidationIssueCode.values.length),
      );
    });
  });

  group('StagePatternValidator 오류 코드', () {
    test('스테이지·패턴 메타데이터 오류를 함께 수집한다', () {
      final pattern = _pattern(
        id: '',
        weight: 0,
        parShots: 0,
        difficultyBand: '',
        solutionFamilies: const {},
      );
      final stage = _stage(id: '', title: '', patterns: [pattern]);

      final report = StagePatternValidator().validate(stage);

      expect(report.isValid, isFalse);
      expect(report.hasCode(ValidationIssueCode.emptyStageId), isTrue);
      expect(report.hasCode(ValidationIssueCode.emptyStageTitle), isTrue);
      expect(
        report.hasCode(ValidationIssueCode.patternCountOutOfRange),
        isTrue,
      );
      expect(report.hasCode(ValidationIssueCode.emptyPatternId), isTrue);
      expect(report.hasCode(ValidationIssueCode.invalidWeight), isTrue);
      expect(report.hasCode(ValidationIssueCode.invalidParShots), isTrue);
      expect(report.hasCode(ValidationIssueCode.emptyDifficultyBand), isTrue);
      expect(
        report.hasCode(ValidationIssueCode.insufficientSolutionFamilies),
        isTrue,
      );
    });

    test('패턴 ID·기물 ID 중복과 예약 ID를 검사한다', () {
      final duplicate = _pattern(
        id: 'same',
        objects: [
          _hole(),
          _object('crate', EntityType.crate, const Vec2(100, 100)),
          _object('crate', EntityType.weight, const Vec2(180, 100)),
          _object('active_ball', EntityType.ball, const Vec2(250, 100)),
          _object('', EntityType.bumper, const Vec2(100, 200)),
        ],
      );
      final stage = _stage(
        patterns: [
          duplicate,
          duplicate,
          _pattern(id: 'third'),
        ],
      );

      final report = StagePatternValidator().validate(stage);

      expect(report.hasCode(ValidationIssueCode.duplicatePatternId), isTrue);
      expect(report.hasCode(ValidationIssueCode.duplicateObjectId), isTrue);
      expect(report.hasCode(ValidationIssueCode.reservedObjectId), isTrue);
      expect(report.hasCode(ValidationIssueCode.emptyObjectId), isTrue);
    });

    test('수치 오류 코드를 필드별로 구분한다', () {
      final bad = _pattern(
        objects: [
          _hole(),
          _object(
            'bad',
            EntityType.crate,
            const Vec2(double.nan, 100),
            size: const Vec2(-1, double.infinity),
            hitboxScale: double.nan,
            restitution: -0.1,
          ),
        ],
        ballSpawn: const Vec2(double.infinity, 20),
      );

      final report = StagePatternValidator().validateLegacyStage(
        _stage(patterns: [bad]),
      );

      expect(report.hasCode(ValidationIssueCode.nonFiniteBallSpawn), isTrue);
      expect(report.hasCode(ValidationIssueCode.nonFinitePosition), isTrue);
      expect(report.hasCode(ValidationIssueCode.nonFiniteSize), isTrue);
      expect(report.hasCode(ValidationIssueCode.nonFiniteHitboxScale), isTrue);
      expect(report.hasCode(ValidationIssueCode.invalidRestitution), isTrue);
    });

    test('크기·히트박스·반발 계수와 기물 수 예산을 검사한다', () {
      final bad = _pattern(
        objects: [
          _hole(),
          _object(
            'bad',
            EntityType.crate,
            const Vec2(100, 100),
            size: const Vec2(0, 10),
            hitboxScale: 0,
            restitution: 1.1,
          ),
        ],
      );

      final report = StagePatternValidator(
        maxObjectCount: 1,
      ).validateLegacyStage(_stage(patterns: [bad]));

      expect(report.hasCode(ValidationIssueCode.invalidSize), isTrue);
      expect(report.hasCode(ValidationIssueCode.invalidHitboxScale), isTrue);
      expect(report.hasCode(ValidationIssueCode.invalidRestitution), isTrue);
      expect(report.hasCode(ValidationIssueCode.objectCountExceeded), isTrue);
    });
  });

  group('StagePatternValidator 배치와 연결', () {
    test('필드 이탈·홀 상태·벽 이동을 검사한다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            objects: [
              _object(
                'hole_a',
                EntityType.hole,
                const Vec2(2, 2),
                size: const Vec2(60, 60),
                solid: true,
                movable: true,
              ),
              _object('hole_b', EntityType.hole, const Vec2(300, 100)),
              _object(
                'wall',
                EntityType.wall,
                const Vec2(180, 500),
                size: const Vec2(40, 200),
                movable: true,
              ),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.hasCode(ValidationIssueCode.objectOutOfBounds), isTrue);
      expect(report.hasCode(ValidationIssueCode.invalidHoleCount), isTrue);
      expect(report.hasCode(ValidationIssueCode.holeIsSolid), isTrue);
      expect(report.hasCode(ValidationIssueCode.holeIsMovable), isTrue);
      expect(report.hasCode(ValidationIssueCode.wallIsMovable), isTrue);
    });

    test('시작 공의 자동 클리어·고체 내부 생성을 검사한다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            ballSpawn: const Vec2(100, 100),
            objects: [
              _holeAt(const Vec2(105, 100)),
              _object(
                'crate',
                EntityType.crate,
                const Vec2(100, 100),
                size: const Vec2(30, 30),
              ),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.hasCode(ValidationIssueCode.ballSpawnOverlapsHole), isTrue);
      expect(report.hasCode(ValidationIssueCode.ballSpawnInsideSolid), isTrue);
    });

    test('시작 홀 포획 경계는 hole.hitboxScale과 무관하다', () {
      final insideDistance = 30.55;
      final outsideDistance = 30.57;
      final validator = StagePatternValidator();

      StageDefinition stageFor(double distance, double hitboxScale) {
        return _stage(
          patterns: [
            _pattern(
              ballSpawn: Vec2(300 + distance, 100),
              objects: [
                _holeAt(const Vec2(300, 100), hitboxScale: hitboxScale),
              ],
            ),
          ],
        );
      }

      final smallInside = validator.validateLegacyStage(
        stageFor(insideDistance, 0.1),
      );
      final largeInside = validator.validateLegacyStage(
        stageFor(insideDistance, 2.0),
      );
      final smallOutside = validator.validateLegacyStage(
        stageFor(outsideDistance, 0.1),
      );
      final largeOutside = validator.validateLegacyStage(
        stageFor(outsideDistance, 2.0),
      );

      expect(
        smallInside.hasCode(ValidationIssueCode.ballSpawnOverlapsHole),
        isTrue,
      );
      expect(
        largeInside.hasCode(ValidationIssueCode.ballSpawnOverlapsHole),
        isTrue,
      );
      expect(
        smallOutside.hasCode(ValidationIssueCode.ballSpawnOverlapsHole),
        isFalse,
      );
      expect(
        largeOutside.hasCode(ValidationIssueCode.ballSpawnOverlapsHole),
        isFalse,
      );
    });

    test('solid=false 벽도 시작 공을 막는 물리 장애물로 검사한다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            ballSpawn: const Vec2(100, 100),
            objects: [
              _hole(),
              _object(
                'thin_wall',
                EntityType.wall,
                const Vec2(100, 100),
                size: const Vec2(40, 40),
                solid: false,
              ),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.hasCode(ValidationIssueCode.ballSpawnInsideSolid), isTrue);
    });

    test('기존 공의 시작 홀 포획과 정상 위치를 구분한다', () {
      final captured = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'previous_ball',
                EntityType.ball,
                const Vec2(325, 100),
                size: const Vec2(24, 24),
              ),
            ],
          ),
        ],
      );
      final normal = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'previous_ball',
                EntityType.ball,
                const Vec2(340, 100),
                size: const Vec2(24, 24),
              ),
            ],
          ),
        ],
      );

      final validator = StagePatternValidator();
      final capturedReport = validator.validateLegacyStage(captured);
      final normalReport = validator.validateLegacyStage(normal);

      expect(
        capturedReport.hasCode(ValidationIssueCode.existingBallOverlapsHole),
        isTrue,
      );
      expect(
        normalReport.hasCode(ValidationIssueCode.existingBallOverlapsHole),
        isFalse,
      );
    });

    test('원형·사각형 초기 겹침은 찾고 단순 접촉은 허용한다', () {
      final overlap = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'circle_a',
                EntityType.ball,
                const Vec2(100, 100),
                size: const Vec2(30, 30),
              ),
              _object(
                'circle_b',
                EntityType.ball,
                const Vec2(120, 100),
                size: const Vec2(30, 30),
              ),
              _object(
                'rect_a',
                EntityType.crate,
                const Vec2(220, 200),
                size: const Vec2(40, 40),
              ),
              _object(
                'rect_b',
                EntityType.crate,
                const Vec2(235, 200),
                size: const Vec2(40, 40),
              ),
            ],
          ),
        ],
      );
      final contact = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'circle_a',
                EntityType.ball,
                const Vec2(100, 100),
                size: const Vec2(30, 30),
              ),
              _object(
                'circle_b',
                EntityType.ball,
                const Vec2(126.4, 100),
                size: const Vec2(30, 30),
              ),
              _object(
                'rect_a',
                EntityType.crate,
                const Vec2(220, 200),
                size: const Vec2(40, 40),
              ),
              _object(
                'rect_b',
                EntityType.crate,
                const Vec2(255.2, 200),
                size: const Vec2(40, 40),
              ),
            ],
          ),
        ],
      );

      final overlapReport = StagePatternValidator().validateLegacyStage(
        overlap,
      );
      final contactReport = StagePatternValidator().validateLegacyStage(
        contact,
      );

      expect(overlapReport.count(ValidationIssueCode.initialObjectOverlap), 2);
      expect(
        contactReport.hasCode(ValidationIssueCode.initialObjectOverlap),
        isFalse,
      );
    });

    test('벽의 필드 모서리 접합과 레거시 비연결 문·스위치를 허용한다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'top',
                EntityType.wall,
                const Vec2(180, 12),
                size: const Vec2(340, 24),
              ),
              _object(
                'left',
                EntityType.wall,
                const Vec2(12, 280),
                size: const Vec2(24, 520),
              ),
              _object('gate', EntityType.gate, const Vec2(250, 250)),
              _object('switch', EntityType.switchPad, const Vec2(100, 400)),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.isValid, isTrue, reason: '${report.issues}');
    });

    test('switch.linkId가 gate.id를 참조하는 연결과 누락을 검사한다', () {
      final missing = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'switch',
                EntityType.switchPad,
                const Vec2(100, 400),
                linkId: 'missing-gate',
              ),
            ],
          ),
        ],
      );
      final mismatch = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'gate',
                EntityType.gate,
                const Vec2(200, 200),
                linkId: 'ignored-gate-link',
                open: true,
              ),
              _object(
                'switch',
                EntityType.switchPad,
                const Vec2(100, 400),
                linkId: 'gate',
                pressed: false,
              ),
            ],
          ),
        ],
      );

      expect(
        StagePatternValidator()
            .validateLegacyStage(missing)
            .hasCode(ValidationIssueCode.missingLinkedTarget),
        isTrue,
      );
      expect(
        StagePatternValidator()
            .validateLegacyStage(missing)
            .count(ValidationIssueCode.missingLinkedTarget),
        1,
      );
      expect(
        StagePatternValidator()
            .validateLegacyStage(mismatch)
            .hasCode(ValidationIssueCode.linkedStateMismatch),
        isTrue,
      );
    });

    test('gate.linkId 없이 switch가 gate ID를 참조하는 정상 fixture를 허용한다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object('gate', EntityType.gate, const Vec2(200, 200)),
              _object(
                'switch',
                EntityType.switchPad,
                const Vec2(100, 400),
                linkId: 'gate',
              ),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.isValid, isTrue, reason: '${report.issues}');
    });

    test('문만·스위치만·모호한 무연결 구성은 누락으로 잡는다', () {
      final gateOnly = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object('gate', EntityType.gate, const Vec2(200, 200)),
            ],
          ),
        ],
      );
      final switchOnly = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object('switch', EntityType.switchPad, const Vec2(100, 400)),
            ],
          ),
        ],
      );
      final ambiguous = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object('gate_a', EntityType.gate, const Vec2(180, 200)),
              _object('gate_b', EntityType.gate, const Vec2(240, 200)),
              _object('switch_a', EntityType.switchPad, const Vec2(100, 380)),
            ],
          ),
        ],
      );

      final validator = StagePatternValidator();
      expect(
        validator
            .validateLegacyStage(gateOnly)
            .hasCode(ValidationIssueCode.missingLinkedTarget),
        isTrue,
      );
      expect(
        validator
            .validateLegacyStage(switchOnly)
            .hasCode(ValidationIssueCode.missingLinkedTarget),
        isTrue,
      );
      expect(
        validator
            .validateLegacyStage(switchOnly)
            .count(ValidationIssueCode.missingLinkedTarget),
        1,
      );
      expect(
        validator
            .validateLegacyStage(ambiguous)
            .hasCode(ValidationIssueCode.missingLinkedTarget),
        isTrue,
      );
    });

    test('열린 문은 초기 물리 겹침에서 장애물로 세지 않는다', () {
      final stage = _stage(
        patterns: [
          _pattern(
            objects: [
              _hole(),
              _object(
                'gate',
                EntityType.gate,
                const Vec2(200, 200),
                size: const Vec2(60, 60),
                open: true,
              ),
              _object(
                'switch',
                EntityType.switchPad,
                const Vec2(100, 400),
                linkId: 'gate',
                pressed: true,
              ),
              _object(
                'crate',
                EntityType.crate,
                const Vec2(200, 200),
                size: const Vec2(60, 60),
              ),
            ],
          ),
        ],
      );

      final report = StagePatternValidator().validateLegacyStage(stage);

      expect(report.hasCode(ValidationIssueCode.initialObjectOverlap), isFalse);
      expect(report.isValid, isTrue, reason: '${report.issues}');
    });

    test('required_reward 메타데이터를 명시적으로 금지한다', () {
      final pattern = _pattern(
        metadata: const {'required_reward': 'heavy_core'},
      );

      final report = StagePatternValidator().validateLegacyStage(
        _stage(patterns: [pattern]),
      );

      expect(report.hasCode(ValidationIssueCode.requiredReward), isTrue);
    });
  });

  group('StagePatternValidator 결과 계약', () {
    test('코드 검색·집계 API와 안정 정렬을 제공한다', () {
      final pattern = _pattern(
        id: 'bad',
        objects: [
          _hole(),
          _object('z', EntityType.crate, const Vec2(10, 10)),
          _object('a', EntityType.crate, const Vec2(10, 10)),
        ],
      );
      final stage = _stage(patterns: [pattern]);
      final validator = StagePatternValidator();

      final first = validator.validateLegacyStage(stage);
      final second = validator.validateLegacyStage(stage);

      expect(first.hasCode(ValidationIssueCode.objectOutOfBounds), isTrue);
      expect(first.count(ValidationIssueCode.initialObjectOverlap), 1);
      expect(
        first.whereCode(ValidationIssueCode.initialObjectOverlap),
        hasLength(1),
      );
      expect(
        first.issues.map((issue) => issue.toString()).toList(),
        second.issues.map((issue) => issue.toString()).toList(),
      );
      expect(first.issues.first.code.schemaName, 'initial_object_overlap');
      expect(first.issues.first.message, isNot(contains(RegExp(r'[A-Za-z]'))));
    });
  });
}

StageDefinition _validStage({String id = 'stage', String title = '테스트'}) {
  return _stage(
    id: id,
    title: title,
    patterns: [
      _pattern(id: 'pattern-a'),
      _pattern(id: 'pattern-b'),
      _pattern(id: 'pattern-c'),
    ],
  );
}

StageDefinition _stage({
  String id = 'stage',
  String title = '테스트',
  required List<StagePattern> patterns,
}) {
  return StageDefinition(stageId: id, title: title, patterns: patterns);
}

StagePattern _pattern({
  String id = 'pattern',
  double weight = 1,
  int parShots = 3,
  String difficultyBand = '보통',
  Vec2 ballSpawn = const Vec2(60, 500),
  List<PatternObjectDefinition>? objects,
  Set<String> solutionFamilies = const {'직선', '반사'},
  Map<String, String> metadata = const {},
}) {
  return StagePattern(
    patternId: id,
    weight: weight,
    parShots: parShots,
    difficultyBand: difficultyBand,
    ballSpawn: ballSpawn,
    objects: objects ?? [_hole()],
    solutionFamilies: solutionFamilies,
    metadata: metadata,
  );
}

PatternObjectDefinition _hole() => _holeAt(const Vec2(300, 100));

PatternObjectDefinition _holeAt(Vec2 position, {double hitboxScale = 0.88}) {
  return PatternObjectDefinition(
    id: 'hole',
    type: EntityType.hole,
    position: position,
    size: const Vec2(40, 40),
    solid: false,
    hitboxScale: hitboxScale,
  );
}

PatternObjectDefinition _object(
  String id,
  EntityType type,
  Vec2 position, {
  Vec2 size = const Vec2(30, 30),
  bool movable = false,
  bool solid = true,
  bool active = true,
  bool open = false,
  bool pressed = false,
  double hitboxScale = 0.88,
  double restitution = 0.72,
  String? linkId,
}) {
  return PatternObjectDefinition(
    id: id,
    type: type,
    position: position,
    size: size,
    movable: movable,
    solid: solid,
    active: active,
    open: open,
    pressed: pressed,
    hitboxScale: hitboxScale,
    restitution: restitution,
    linkId: linkId,
  );
}
