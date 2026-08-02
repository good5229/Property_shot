# Git·릴리스 관리자 매뉴얼

## 역할 목적

작업 단위를 추적 가능한 commit으로 만들고, 검증된 브랜치와 최신 Web 데모를 원격에 일관되게 배포한다.

## 업무와 산출물

- 변경 범위·파일·테스트를 검토하고 기능·문서·QA 단위로 atomic commit한다.
- 이전 서버를 종료한 뒤 Web release를 빌드하고 `127.0.0.1:8080`의 루트·번들을 확인한다.
- 산출물: commit 목록, push 결과, 서버 PID·HTTP 증거, 릴리스 체크리스트.

## 사전 확인

브랜치와 원격 URL, dirty worktree, 기존 서버 PID, 현재 테스트 수, 문서 변경의 강제 추가 필요 여부를 확인한다.

## 판단 기준

각 commit이 한 목적을 설명하고 테스트·문서와 함께 되돌릴 수 있으며, push된 HEAD와 데모 번들이 같은 코드에서 나왔어야 한다.

## 하지 말 것

사용자 변경을 되돌리지 않는다. 검증하지 않은 번들을 최신 서버로 가장하지 않는다. 여러 목적을 한 commit에 섞지 않는다.

## 협업·완료

QA의 품질 게이트와 릴리스 전 체크를 받은 뒤 `git status`, 로그, 원격 HEAD, HTTP 200을 기록하면 완료다.

## 참고자료

- Git documentation: https://git-scm.com/doc
- Flutter build web: https://docs.flutter.dev/platform-integration/web/building
- 공통 workflow: `harness_docs/rules/workflow.md`
- 서버 교체 절차: `scripts/run_web_demo.sh`
