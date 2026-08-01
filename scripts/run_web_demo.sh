#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${PORT:-8080}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"
PID_FILE="$ROOT_DIR/.runtime/property_shot_web_${PORT}.pid"
LOG_FILE="$ROOT_DIR/.runtime/property_shot_web_${PORT}.log"

mkdir -p "$ROOT_DIR/.runtime"

stop_existing_server() {
  local pids pid command_line
  pids="$(lsof -ti tcp:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
  for pid in $pids; do
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    case "$command_line" in
      *"http.server"*)
        echo "기존 데모 서버 종료: PID $pid"
        kill "$pid"
        for _ in $(seq 1 20); do
          kill -0 "$pid" 2>/dev/null || break
          sleep 0.1
        done
        ;;
      *)
        echo "8080 포트가 다른 프로세스에 의해 사용 중입니다: PID $pid" >&2
        echo "$command_line" >&2
        exit 1
        ;;
    esac
  done
}

stop_existing_server
echo "Web release 빌드 시작"
"$FLUTTER_BIN" build web --release

echo "최신 데모 서버 시작: http://127.0.0.1:$PORT"
nohup python3 -m http.server "$PORT" --directory "$ROOT_DIR/build/web" \
  >"$LOG_FILE" 2>&1 &
server_pid=$!
echo "$server_pid" >"$PID_FILE"

cleanup() {
  kill "$server_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for _ in $(seq 1 30); do
  root_status="$(curl --max-time 1 -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" || true)"
  bundle_status="$(curl --max-time 1 -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/main.dart.js" || true)"
  if [ "$root_status" = "200" ] && [ "$bundle_status" = "200" ]; then
    echo "검증 완료: 루트 $root_status, 번들 $bundle_status, PID $server_pid"
    echo "서버 실행 중. 종료하려면 Ctrl+C를 누르세요."
    wait "$server_pid"
    exit 0
  fi
  sleep 0.2
done

echo "데모 서버 검증 실패. 로그: $LOG_FILE" >&2
kill "$server_pid" 2>/dev/null || true
exit 1
