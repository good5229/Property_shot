#!/usr/bin/env bash
set -euo pipefail

flutter test --concurrency=1 --reporter=compact
dart run tool/long_session_performance_probe.dart 1200
