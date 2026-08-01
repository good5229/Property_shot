# 번들 자산 목록

이 문서는 출시 빌드에 포함되는 시각 자산을 추적하기 위한 템플릿이다. `build/` 산출물은 저장소에 커밋하지 않으며, 서명 빌드 직전에 목록과 해시를 재생성한다.

## 앱 자산

| 경로 | 용도 | 권리 상태 |
|---|---|---|
| `assets/icons/ball.png` | 공 썸네일·게임 공 | CC0 원본, 권리대장 확인 |
| `assets/icons/crate.png` | 상자 썸네일·게임 오브젝트 | CC0 원본, 권리대장 확인 |
| `assets/icons/stone_boulder.png` | 돌 썸네일·게임 오브젝트 | CC0 원본, 권리대장 확인 |
| `assets/icons/property_shot_app_icon_source.png` | 앱 아이콘 원본 | 프로젝트 전용 생성 이미지 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | iOS 아이콘 파생 파일 | 원본에서 규격별 생성 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | 런치 화면 | 프로젝트 전용 구성 |

## 재현 명령

```bash
find assets/icons ios/Runner/Assets.xcassets -type f -print0 | sort -z | xargs -0 shasum -a 256
```

## 제출 전 확인

- [ ] 서명된 최종 앱에서 위 경로가 실제 포함되는지 확인
- [ ] 최종 IPA 또는 앱 번들의 해시를 별도 보관
- [ ] 권리대장의 검토자·검토일을 기록
