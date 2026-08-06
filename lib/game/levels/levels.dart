import '../domain/geometry.dart';
import '../domain/level_definition.dart';
import 'generated_stage_catalog.dart';

const logicalSize = Vec2(360, 560);

/// 생성된 카탈로그에서 baseline metadata로 표시된 기준 패턴만 노출하는
/// 기존 동기식 API다.
/// 추가 패턴 추첨과 런 상태 연결은 후속 작업에서 별도로 수행한다.
final List<LevelDefinition> levels = generatedStageCatalog.baselineLevels();
