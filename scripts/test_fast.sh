#!/usr/bin/env bash
set -euo pipefail

flutter analyze
flutter test --concurrency=1 --reporter=compact \
  test/play_telemetry_test.dart \
  test/game_feedback_test.dart \
  test/island_restoration_test.dart \
  test/weekly_lab_test.dart \
  test/replay_comparison_test.dart \
  test/progress_store_test.dart \
  test/stage_pattern_validator_test.dart \
  test/widget_test.dart
