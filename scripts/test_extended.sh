#!/usr/bin/env bash
set -euo pipefail

flutter analyze
dart run tool/generate_stage_catalog.dart --check
dart run tool/generate_hint_catalog.dart --check
flutter test --concurrency=1 --reporter=compact
dart run tool/long_session_performance_probe.dart 1200
