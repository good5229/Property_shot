// 자동 생성 파일입니다. 직접 편집하지 마세요.
// assets/stages/chapter_1.json에서 결정론적으로 생성됩니다.
// JSON 원본이 기준 데이터이며 이 Dart 파일은 동기 실행용 스냅샷입니다.

import '../domain/stage_catalog.dart';

const generatedStageCatalogJson = r'''
{
  "schemaVersion": 1,
  "stages": [
    {
      "stageId": "stage_heavy",
      "title": "1. 무거움 익히기",
      "patterns": [
        {
          "patternId": "stage_heavy_01",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 456.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 302.0,
                "y": 132.0
              },
              "size": {
                "x": 64.0,
                "y": 64.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_a",
              "type": "crate",
              "position": {
                "x": 178.0,
                "y": 286.0
              },
              "size": {
                "x": 42.0,
                "y": 42.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.82,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "anvil",
              "type": "weight",
              "position": {
                "x": 78.0,
                "y": 154.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.84,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "3회 이하로 상자와 홀의 길을 완성하세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "anvil",
          "acceptedStrategyIds": [
            "anvil",
            "none"
          ],
          "solutionFamilies": [
            "crate_push",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "무거운 공으로 상자 밀기",
            "속성 없이 성공"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_heavy_02",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 62.0,
            "y": 472.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 120.0
              },
              "size": {
                "x": 52.0,
                "y": 52.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_a",
              "type": "crate",
              "position": {
                "x": 188.0,
                "y": 326.0
              },
              "size": {
                "x": 42.0,
                "y": 42.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.82,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "anvil",
              "type": "weight",
              "position": {
                "x": 88.0,
                "y": 188.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.84,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "reflection_wall_a",
              "type": "wall",
              "position": {
                "x": 214.0,
                "y": 246.0
              },
              "size": {
                "x": 150.0,
                "y": 20.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "reflection_wall_b",
              "type": "wall",
              "position": {
                "x": 278.0,
                "y": 360.0
              },
              "size": {
                "x": 20.0,
                "y": 168.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "heavy_02_bypass_blocker",
              "type": "wall",
              "position": {
                "x": 300.0,
                "y": 486.0
              },
              "size": {
                "x": 20.0,
                "y": 20.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "3회 이하로 상자와 홀의 길을 완성하세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "anvil",
          "acceptedStrategyIds": [
            "anvil",
            "none"
          ],
          "solutionFamilies": [
            "multi_wall_reflection",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "벽 세 번 반사",
            "서로 다른 벽을 이어서 반사"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_heavy_03",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 58.0,
            "y": 468.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 304.0,
                "y": 116.0
              },
              "size": {
                "x": 52.0,
                "y": 52.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_a",
              "type": "crate",
              "position": {
                "x": 164.0,
                "y": 304.0
              },
              "size": {
                "x": 42.0,
                "y": 42.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.82,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "anvil",
              "type": "weight",
              "position": {
                "x": 90.0,
                "y": 174.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.84,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_lane",
              "type": "wall",
              "position": {
                "x": 286.0,
                "y": 430.0
              },
              "size": {
                "x": 100.0,
                "y": 20.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_b",
              "type": "crate",
              "position": {
                "x": 248.0,
                "y": 262.0
              },
              "size": {
                "x": 46.0,
                "y": 46.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.82,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "3회 이하로 상자와 홀의 길을 완성하세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "anvil",
          "acceptedStrategyIds": [
            "anvil",
            "none"
          ],
          "solutionFamilies": [
            "crate_push",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "두 상자 배치에서 연쇄 시도",
            "속성 없이 성공"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_heavy_04",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 74.0,
            "y": 446.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 138.0
              },
              "size": {
                "x": 52.0,
                "y": 52.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_a",
              "type": "crate",
              "position": {
                "x": 214.0,
                "y": 350.0
              },
              "size": {
                "x": 42.0,
                "y": 42.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.82,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "anvil",
              "type": "weight",
              "position": {
                "x": 104.0,
                "y": 226.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.84,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_detour_a",
              "type": "wall",
              "position": {
                "x": 146.0,
                "y": 266.0
              },
              "size": {
                "x": 164.0,
                "y": 20.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_detour_b",
              "type": "wall",
              "position": {
                "x": 264.0,
                "y": 206.0
              },
              "size": {
                "x": 20.0,
                "y": 116.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "3회 이하로 상자와 홀의 길을 완성하세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "anvil",
          "acceptedStrategyIds": [
            "anvil",
            "none"
          ],
          "solutionFamilies": [
            "crate_push",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "상자 충돌 시도",
            "속성 없이 우회 시도"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_bouncy",
      "title": "2. 탄성 익히기",
      "patterns": [
        {
          "patternId": "stage_bouncy_01",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 58.0,
            "y": 462.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 298.0,
                "y": 130.0
              },
              "size": {
                "x": 74.0,
                "y": 74.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "blocker",
              "type": "wall",
              "position": {
                "x": 220.0,
                "y": 270.0
              },
              "size": {
                "x": 24.0,
                "y": 300.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "approach_guard",
              "type": "wall",
              "position": {
                "x": 95.0,
                "y": 210.0
              },
              "size": {
                "x": 46.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "route_guard_lower",
              "type": "wall",
              "position": {
                "x": 165.0,
                "y": 350.0
              },
              "size": {
                "x": 70.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "jelly",
              "type": "bumper",
              "position": {
                "x": 300.0,
                "y": 450.0
              },
              "size": {
                "x": 58.0,
                "y": 42.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "젤리와 한 번 부딪힌 뒤 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "jelly",
          "acceptedStrategyIds": [
            "jelly",
            "none"
          ],
          "solutionFamilies": [
            "multi_wall_reflection",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "one_shot",
            "two_wall_banks"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_bouncy_02",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 58.0,
            "y": 462.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 110.0
              },
              "size": {
                "x": 60.0,
                "y": 60.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "bank_center_horizontal",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 310.0
              },
              "size": {
                "x": 170.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "jelly",
              "type": "bumper",
              "position": {
                "x": 180.0,
                "y": 360.0
              },
              "size": {
                "x": 58.0,
                "y": 42.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "젤리를 거쳐 벽을 반사하거나 벽을 이용해 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "jelly",
          "acceptedStrategyIds": [
            "jelly",
            "none"
          ],
          "solutionFamilies": [
            "jelly_interaction",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "jelly_hit",
            "one_shot"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_bouncy_03",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 58.0,
            "y": 462.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 110.0
              },
              "size": {
                "x": 52.0,
                "y": 52.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "bank_center_horizontal",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 310.0
              },
              "size": {
                "x": 170.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "route_guard_vertical",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 450.0
              },
              "size": {
                "x": 24.0,
                "y": 180.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "jelly",
              "type": "bumper",
              "position": {
                "x": 222.0,
                "y": 360.0
              },
              "size": {
                "x": 58.0,
                "y": 42.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "젤리의 반발과 열린 통로를 이용해 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "jelly",
          "acceptedStrategyIds": [
            "jelly",
            "none"
          ],
          "solutionFamilies": [
            "multi_wall_reflection",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "one_shot",
            "two_wall_banks"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_bouncy_04",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 300.0,
            "y": 462.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 100.0,
                "y": 110.0
              },
              "size": {
                "x": 52.0,
                "y": 52.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.12,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.52,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "jelly",
              "type": "bumper",
              "position": {
                "x": 180.0,
                "y": 360.0
              },
              "size": {
                "x": 58.0,
                "y": 42.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "bouncy_04_goal_blocker",
              "type": "wall",
              "position": {
                "x": 100.0,
                "y": 170.0
              },
              "size": {
                "x": 120.0,
                "y": 20.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "젤리와 벽의 반발 각도를 조절해 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "jelly",
          "acceptedStrategyIds": [
            "jelly",
            "none"
          ],
          "solutionFamilies": [
            "multi_wall_reflection",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "two_wall_banks",
            "upper_wall_bank"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_chain_gate",
      "title": "3. 연쇄 문 열기",
      "patterns": [
        {
          "patternId": "stage_chain_gate_01",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 304.0,
                "y": 96.0
              },
              "size": {
                "x": 62.0,
                "y": 62.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "gate",
              "type": "gate",
              "position": {
                "x": 238.0,
                "y": 226.0
              },
              "size": {
                "x": 44.0,
                "y": 118.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "switch",
              "type": "switch_pad",
              "position": {
                "x": 154.0,
                "y": 352.0
              },
              "size": {
                "x": 100.0,
                "y": 22.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "steel",
              "type": "weight",
              "position": {
                "x": 80.0,
                "y": 146.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "glue",
              "type": "sticky_surface",
              "position": {
                "x": 300.0,
                "y": 334.0
              },
              "size": {
                "x": 50.0,
                "y": 86.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_b",
              "type": "crate",
              "position": {
                "x": 154.0,
                "y": 292.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "스위치를 눌러 문을 열고 홀에 넣어 보세요.",
          "copyCoreReward": 1,
          "intendedStrategyId": "steel",
          "acceptedStrategyIds": [
            "glue",
            "none",
            "steel"
          ],
          "solutionFamilies": [
            "none_direct",
            "steel_switch"
          ],
          "optionalChallenges": [
            "one_shot",
            "switch_and_hole"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_chain_gate_02",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 300.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 80.0,
                "y": 120.0
              },
              "size": {
                "x": 50.0,
                "y": 50.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "gate",
              "type": "gate",
              "position": {
                "x": 238.0,
                "y": 226.0
              },
              "size": {
                "x": 44.0,
                "y": 118.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "switch",
              "type": "switch_pad",
              "position": {
                "x": 260.0,
                "y": 352.0
              },
              "size": {
                "x": 100.0,
                "y": 22.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "steel",
              "type": "weight",
              "position": {
                "x": 260.0,
                "y": 146.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "glue",
              "type": "sticky_surface",
              "position": {
                "x": 50.0,
                "y": 210.0
              },
              "size": {
                "x": 50.0,
                "y": 86.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_b",
              "type": "crate",
              "position": {
                "x": 180.0,
                "y": 310.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "스위치를 눌러 문을 열고 홀에 넣어 보세요.",
          "copyCoreReward": 1,
          "intendedStrategyId": "steel",
          "acceptedStrategyIds": [
            "glue",
            "none",
            "steel"
          ],
          "solutionFamilies": [
            "glue_preparation",
            "none_direct",
            "steel_switch"
          ],
          "optionalChallenges": [
            "one_shot",
            "prepare_with_glue",
            "switch_and_hole"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_chain_gate_03",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 100.0
              },
              "size": {
                "x": 50.0,
                "y": 50.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "gate",
              "type": "gate",
              "position": {
                "x": 238.0,
                "y": 226.0
              },
              "size": {
                "x": 44.0,
                "y": 118.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "switch",
              "type": "switch_pad",
              "position": {
                "x": 100.0,
                "y": 300.0
              },
              "size": {
                "x": 100.0,
                "y": 22.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "steel",
              "type": "weight",
              "position": {
                "x": 80.0,
                "y": 146.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "glue",
              "type": "sticky_surface",
              "position": {
                "x": 300.0,
                "y": 300.0
              },
              "size": {
                "x": 50.0,
                "y": 86.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_b",
              "type": "crate",
              "position": {
                "x": 210.0,
                "y": 430.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "스위치를 누르는 길과 벽을 이용하는 길을 모두 찾아보세요.",
          "copyCoreReward": 1,
          "intendedStrategyId": "steel",
          "acceptedStrategyIds": [
            "glue",
            "none",
            "steel"
          ],
          "solutionFamilies": [
            "none_direct",
            "steel_switch"
          ],
          "optionalChallenges": [
            "one_shot",
            "switch_and_hole"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_chain_gate_04",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 300.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 100.0
              },
              "size": {
                "x": 50.0,
                "y": 50.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "gate",
              "type": "gate",
              "position": {
                "x": 238.0,
                "y": 226.0
              },
              "size": {
                "x": 44.0,
                "y": 118.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "switch",
              "type": "switch_pad",
              "position": {
                "x": 260.0,
                "y": 300.0
              },
              "size": {
                "x": 100.0,
                "y": 22.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "steel",
              "type": "weight",
              "position": {
                "x": 80.0,
                "y": 146.0
              },
              "size": {
                "x": 52.0,
                "y": 38.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "glue",
              "type": "sticky_surface",
              "position": {
                "x": 70.0,
                "y": 260.0
              },
              "size": {
                "x": 50.0,
                "y": 86.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_b",
              "type": "crate",
              "position": {
                "x": 180.0,
                "y": 430.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "문을 여는 길과 문을 피해 가는 길을 모두 찾아보세요.",
          "copyCoreReward": 1,
          "intendedStrategyId": "steel",
          "acceptedStrategyIds": [
            "glue",
            "none",
            "steel"
          ],
          "solutionFamilies": [
            "none_direct",
            "steel_switch"
          ],
          "optionalChallenges": [
            "one_shot",
            "switch_and_hole"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_balloon",
      "title": "4. 풍선 터뜨리기",
      "patterns": [
        {
          "patternId": "stage_balloon_01",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 128.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.1188888889,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_gate",
              "type": "gate",
              "position": {
                "x": 270.0,
                "y": 220.0
              },
              "size": {
                "x": 38.0,
                "y": 74.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon_switch",
              "type": "switch_pad",
              "position": {
                "x": 214.0,
                "y": 214.0
              },
              "size": {
                "x": 62.0,
                "y": 40.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "hidden",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon",
              "type": "balloon",
              "position": {
                "x": 184.0,
                "y": 260.0
              },
              "size": {
                "x": 52.0,
                "y": 58.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.91,
              "linkId": "balloon_switch",
              "movableWhenDrained": false
            },
            {
              "id": "spike_source",
              "type": "spike_source",
              "position": {
                "x": 78.0,
                "y": 142.0
              },
              "size": {
                "x": 58.0,
                "y": 50.0
              },
              "traits": [
                "sharp"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_crate",
              "type": "crate",
              "position": {
                "x": 98.0,
                "y": 400.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "풍선을 밀어도, 터뜨려도 홀에 도착할 수 있습니다.",
          "copyCoreReward": 0,
          "intendedStrategyId": "spike_source",
          "acceptedStrategyIds": [
            "none",
            "spike_source"
          ],
          "solutionFamilies": [
            "none_bypass",
            "sharp_pop_chain"
          ],
          "optionalChallenges": [
            "one_shot",
            "sharp_pop_chain"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_balloon_02",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 100.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.1188888889,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_gate",
              "type": "gate",
              "position": {
                "x": 270.0,
                "y": 176.0
              },
              "size": {
                "x": 38.0,
                "y": 74.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon_switch",
              "type": "switch_pad",
              "position": {
                "x": 214.0,
                "y": 214.0
              },
              "size": {
                "x": 62.0,
                "y": 40.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "hidden",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon",
              "type": "balloon",
              "position": {
                "x": 160.0,
                "y": 260.0
              },
              "size": {
                "x": 52.0,
                "y": 58.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.91,
              "linkId": "balloon_switch",
              "movableWhenDrained": false
            },
            {
              "id": "spike_source",
              "type": "spike_source",
              "position": {
                "x": 78.0,
                "y": 142.0
              },
              "size": {
                "x": 58.0,
                "y": 50.0
              },
              "traits": [
                "sharp"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_crate",
              "type": "crate",
              "position": {
                "x": 120.0,
                "y": 400.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_02_left_return_blocker",
              "type": "wall",
              "position": {
                "x": 55.0,
                "y": 205.0
              },
              "size": {
                "x": 20.0,
                "y": 50.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "풍선을 밀어도, 터뜨려도 홀에 도착할 수 있습니다.",
          "copyCoreReward": 0,
          "intendedStrategyId": "spike_source",
          "acceptedStrategyIds": [
            "none",
            "spike_source"
          ],
          "solutionFamilies": [
            "balloon_bounce",
            "sharp_pop_chain"
          ],
          "optionalChallenges": [
            "one_shot",
            "ordinary_balloon_bounce",
            "sharp_pop_chain"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_balloon_03",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 80.0,
                "y": 128.0
              },
              "size": {
                "x": 76.0,
                "y": 76.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_gate",
              "type": "gate",
              "position": {
                "x": 270.0,
                "y": 176.0
              },
              "size": {
                "x": 38.0,
                "y": 74.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon_switch",
              "type": "switch_pad",
              "position": {
                "x": 214.0,
                "y": 214.0
              },
              "size": {
                "x": 62.0,
                "y": 40.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "hidden",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon",
              "type": "balloon",
              "position": {
                "x": 220.0,
                "y": 300.0
              },
              "size": {
                "x": 52.0,
                "y": 58.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.91,
              "linkId": "balloon_switch",
              "movableWhenDrained": false
            },
            {
              "id": "spike_source",
              "type": "spike_source",
              "position": {
                "x": 150.0,
                "y": 80.0
              },
              "size": {
                "x": 58.0,
                "y": 50.0
              },
              "traits": [
                "sharp"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_crate",
              "type": "crate",
              "position": {
                "x": 220.0,
                "y": 410.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_03_direct_lane_blocker",
              "type": "wall",
              "position": {
                "x": 75.0,
                "y": 350.0
              },
              "size": {
                "x": 30.0,
                "y": 120.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_03_bypass_filter",
              "type": "wall",
              "position": {
                "x": 125.0,
                "y": 340.0
              },
              "size": {
                "x": 14.0,
                "y": 50.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_03_left_bank_blocker",
              "type": "wall",
              "position": {
                "x": 70.0,
                "y": 250.0
              },
              "size": {
                "x": 80.0,
                "y": 20.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "풍선을 밀어도, 터뜨려도 홀에 도착할 수 있습니다.",
          "copyCoreReward": 0,
          "intendedStrategyId": "spike_source",
          "acceptedStrategyIds": [
            "none",
            "spike_source"
          ],
          "solutionFamilies": [
            "none_bypass",
            "sharp_pop_direct"
          ],
          "optionalChallenges": [
            "one_shot",
            "sharp_pop_without_switch"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_balloon_04",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "튜토리얼",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 128.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.1188888889,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_gate",
              "type": "gate",
              "position": {
                "x": 270.0,
                "y": 220.0
              },
              "size": {
                "x": 38.0,
                "y": 74.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon_switch",
              "type": "switch_pad",
              "position": {
                "x": 214.0,
                "y": 214.0
              },
              "size": {
                "x": 62.0,
                "y": 40.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "hidden",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "balloon_gate",
              "movableWhenDrained": false
            },
            {
              "id": "balloon",
              "type": "balloon",
              "position": {
                "x": 150.0,
                "y": 260.0
              },
              "size": {
                "x": 52.0,
                "y": 58.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.91,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "spike_source",
              "type": "spike_source",
              "position": {
                "x": 78.0,
                "y": 142.0
              },
              "size": {
                "x": 58.0,
                "y": 50.0
              },
              "traits": [
                "sharp"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_crate",
              "type": "crate",
              "position": {
                "x": 98.0,
                "y": 340.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "balloon_b",
              "type": "balloon",
              "position": {
                "x": 250.0,
                "y": 300.0
              },
              "size": {
                "x": 52.0,
                "y": 58.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.91,
              "linkId": "balloon_switch",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "풍선을 밀어도, 터뜨려도 홀에 도착할 수 있습니다.",
          "copyCoreReward": 0,
          "intendedStrategyId": "spike_source",
          "acceptedStrategyIds": [
            "none",
            "spike_source"
          ],
          "solutionFamilies": [
            "balloon_bounce",
            "sharp_single_use"
          ],
          "optionalChallenges": [
            "one_shot",
            "ordinary_balloon_bounce",
            "two_balloons_one_sharp"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_drained",
      "title": "5. 비워진 속성",
      "patterns": [
        {
          "patternId": "stage_drained_01",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 178.0,
                "y": 100.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drain_weight",
              "type": "weight",
              "position": {
                "x": 178.0,
                "y": 286.0
              },
              "size": {
                "x": 56.0,
                "y": 52.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.86,
              "restitution": 0.62,
              "linkId": null,
              "movableWhenDrained": true
            },
            {
              "id": "weight_route_ball",
              "type": "ball",
              "position": {
                "x": 178.0,
                "y": 205.0
              },
              "size": {
                "x": 24.0,
                "y": 24.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "spent",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "side_crate",
              "type": "crate",
              "position": {
                "x": 286.0,
                "y": 330.0
              },
              "size": {
                "x": 50.0,
                "y": 50.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drained_01_direct_guard",
              "type": "wall",
              "position": {
                "x": 71.5,
                "y": 438.6
              },
              "size": {
                "x": 12.0,
                "y": 28.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.78,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "비워진 원본을 움직인 뒤 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "drain_weight",
          "acceptedStrategyIds": [
            "drain_weight",
            "none"
          ],
          "solutionFamilies": [
            "drained_weight_push",
            "outer_wall_bypass"
          ],
          "optionalChallenges": [
            "drained_source_moved",
            "without_copy_core"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_drained_02",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 300.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 62.0,
                "y": 104.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drain_jelly",
              "type": "bumper",
              "position": {
                "x": 180.0,
                "y": 286.0
              },
              "size": {
                "x": 58.0,
                "y": 62.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.86,
              "restitution": 0.9,
              "linkId": null,
              "movableWhenDrained": true
            },
            {
              "id": "lane_crate",
              "type": "crate",
              "position": {
                "x": 74.0,
                "y": 330.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drained_02_bypass_blocker",
              "type": "wall",
              "position": {
                "x": 205.0,
                "y": 170.0
              },
              "size": {
                "x": 70.0,
                "y": 110.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "비워진 원본을 움직인 뒤 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "drain_jelly",
          "acceptedStrategyIds": [
            "drain_jelly",
            "none"
          ],
          "solutionFamilies": [
            "drained_jelly_lane",
            "elastic_bank"
          ],
          "optionalChallenges": [
            "drained_source_moved",
            "without_copy_core"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_drained_03",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 179.0,
            "y": 456.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 179.0,
                "y": 160.0
              },
              "size": {
                "x": 100.0,
                "y": 100.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drain_glue",
              "type": "sticky_surface",
              "position": {
                "x": 179.0,
                "y": 286.0
              },
              "size": {
                "x": 80.0,
                "y": 50.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.28,
              "linkId": null,
              "movableWhenDrained": true
            },
            {
              "id": "glue_route_ball",
              "type": "ball",
              "position": {
                "x": 179.0,
                "y": 240.0
              },
              "size": {
                "x": 40.0,
                "y": 40.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "spent",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "bypass_crate",
              "type": "crate",
              "position": {
                "x": 282.0,
                "y": 360.0
              },
              "size": {
                "x": 46.0,
                "y": 46.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drained_03_bypass_blocker",
              "type": "wall",
              "position": {
                "x": 62.0,
                "y": 320.0
              },
              "size": {
                "x": 26.0,
                "y": 70.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "비워진 원본을 움직인 뒤 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "drain_glue",
          "acceptedStrategyIds": [
            "drain_glue",
            "none"
          ],
          "solutionFamilies": [
            "drained_sticky_lane",
            "long_side_bypass"
          ],
          "optionalChallenges": [
            "drained_source_moved",
            "without_copy_core"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_drained_04",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 180.0,
            "y": 478.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 180.0,
                "y": 88.0
              },
              "size": {
                "x": 74.0,
                "y": 74.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "drain_weight_choice",
              "type": "weight",
              "position": {
                "x": 154.0,
                "y": 300.0
              },
              "size": {
                "x": 52.0,
                "y": 50.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.84,
              "restitution": 0.62,
              "linkId": null,
              "movableWhenDrained": true
            },
            {
              "id": "drain_jelly_choice",
              "type": "bumper",
              "position": {
                "x": 218.0,
                "y": 230.0
              },
              "size": {
                "x": 54.0,
                "y": 58.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.84,
              "restitution": 0.9,
              "linkId": null,
              "movableWhenDrained": true
            },
            {
              "id": "choice_crate",
              "type": "crate",
              "position": {
                "x": 92.0,
                "y": 210.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "비워진 원본을 움직인 뒤 홀에 넣어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "drain_weight_choice",
          "acceptedStrategyIds": [
            "drain_jelly_choice",
            "drain_weight_choice",
            "none"
          ],
          "solutionFamilies": [
            "bouncy_right_choice",
            "center_bypass",
            "heavy_left_choice"
          ],
          "optionalChallenges": [
            "two_sources_explored",
            "without_copy_core"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_speed",
      "title": "6. 속도를 되살리는 길",
      "patterns": [
        {
          "patternId": "stage_speed_01",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 56.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 270.0
              },
              "size": {
                "x": 68.0,
                "y": 68.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "last_slider",
              "type": "power_slider",
              "position": {
                "x": 180.0,
                "y": 370.0
              },
              "size": {
                "x": 112.0,
                "y": 48.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 42.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "quiet_crate",
              "type": "crate",
              "position": {
                "x": 76.0,
                "y": 210.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "speed_01_direct_guard",
              "type": "wall",
              "position": {
                "x": 93.0,
                "y": 437.0
              },
              "size": {
                "x": 18.0,
                "y": 36.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.78,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "약한 발사로 발판에 들어가 속도를 되살려 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "slider_last_lane",
          "acceptedStrategyIds": [
            "none",
            "slider_last_lane"
          ],
          "solutionFamilies": [
            "last_segment_reacceleration",
            "outer_wall_bypass"
          ],
          "optionalChallenges": [
            "weak_launch_slider",
            "without_slider"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_speed_02",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 72.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 72.0,
                "y": 104.0
              },
              "size": {
                "x": 68.0,
                "y": 68.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "bank_wall",
              "type": "wall",
              "position": {
                "x": 224.0,
                "y": 298.0
              },
              "size": {
                "x": 18.0,
                "y": 250.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.78,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "after_bank_slider",
              "type": "power_slider",
              "position": {
                "x": 138.0,
                "y": 226.0
              },
              "size": {
                "x": 106.0,
                "y": 46.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 0.0,
                "y": -1.0
              },
              "referenceSpeed": 40.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "quiet_crate",
              "type": "crate",
              "position": {
                "x": 292.0,
                "y": 430.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "speed_02_direct_guard",
              "type": "wall",
              "position": {
                "x": 72.0,
                "y": 350.0
              },
              "size": {
                "x": 34.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.78,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "벽에 맞은 뒤 발판에 들어가는 각도를 찾아 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "wall_then_slider",
          "acceptedStrategyIds": [
            "none",
            "wall_then_slider"
          ],
          "solutionFamilies": [
            "outer_wall_bypass",
            "wall_reflection_slider"
          ],
          "optionalChallenges": [
            "weak_launch_slider",
            "without_slider"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_speed_03",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 62.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 270.0,
                "y": 160.0
              },
              "size": {
                "x": 76.0,
                "y": 76.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "push_crate",
              "type": "crate",
              "position": {
                "x": 118.0,
                "y": 390.0
              },
              "size": {
                "x": 36.0,
                "y": 36.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.84,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "crate_slider",
              "type": "power_slider",
              "position": {
                "x": 118.0,
                "y": 330.0
              },
              "size": {
                "x": 94.0,
                "y": 46.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 0.0,
                "y": -1.0
              },
              "referenceSpeed": 44.0,
              "allowedTargets": [
                "ball",
                "crate"
              ]
            },
            {
              "id": "side_wall",
              "type": "wall",
              "position": {
                "x": 300.0,
                "y": 300.0
              },
              "size": {
                "x": 18.0,
                "y": 180.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.75,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "상자를 건드린 뒤 이어지는 발판의 힘을 활용해 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "crate_then_slider",
          "acceptedStrategyIds": [
            "crate_then_slider",
            "none"
          ],
          "solutionFamilies": [
            "crate_push_reacceleration",
            "outer_wall_bypass"
          ],
          "optionalChallenges": [
            "weak_launch_slider",
            "without_slider"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_speed_04",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "기초 응용",
          "ballSpawn": {
            "x": 180.0,
            "y": 466.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 180.0,
                "y": 96.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "left_slider",
              "type": "power_slider",
              "position": {
                "x": 118.0,
                "y": 298.0
              },
              "size": {
                "x": 86.0,
                "y": 48.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 34.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "right_slider",
              "type": "power_slider",
              "position": {
                "x": 242.0,
                "y": 298.0
              },
              "size": {
                "x": 86.0,
                "y": 48.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": -1.0,
                "y": 0.0
              },
              "referenceSpeed": 46.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "choice_crate",
              "type": "crate",
              "position": {
                "x": 74.0,
                "y": 188.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.86,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "speed_04_direct_guard",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 420.0
              },
              "size": {
                "x": 34.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.78,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "서로 다른 발판을 골라 같은 홀에 도달해 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "choose_slider",
          "acceptedStrategyIds": [
            "choose_slider",
            "none"
          ],
          "solutionFamilies": [
            "center_bypass",
            "multiple_slider_choice"
          ],
          "optionalChallenges": [
            "weak_launch_slider",
            "without_slider"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_persistent",
      "title": "7. 공은 사라지지 않는다",
      "patterns": [
        {
          "patternId": "stage_persistent_01",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 480.0
              },
              "size": {
                "x": 68.0,
                "y": 68.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "cushion_wall",
              "type": "wall",
              "position": {
                "x": 236.0,
                "y": 360.0
              },
              "size": {
                "x": 18.0,
                "y": 180.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "cushion_crate",
              "type": "crate",
              "position": {
                "x": 154.0,
                "y": 300.0
              },
              "size": {
                "x": 50.0,
                "y": 50.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "sequence_switch_p1",
              "type": "switch_pad",
              "position": {
                "x": 254.0,
                "y": 544.0
              },
              "size": {
                "x": 10.0,
                "y": 10.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "p1_setup_gate",
              "movableWhenDrained": false
            },
            {
              "id": "p1_setup_gate",
              "type": "gate",
              "position": {
                "x": 240.0,
                "y": 500.0
              },
              "size": {
                "x": 24.0,
                "y": 70.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "p1_setup_gate",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "첫 번째 공을 쿠션처럼 이용해 두 공으로 홀에 들어가 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "past_ball_cushion",
          "acceptedStrategyIds": [
            "none",
            "past_ball_cushion"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "past_ball_cushion"
          ],
          "optionalChallenges": [
            "previous_ball_cushion",
            "single_shot_bypass"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_persistent_02",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 296.0,
                "y": 178.0
              },
              "size": {
                "x": 70.0,
                "y": 70.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "switch_hold",
              "type": "switch_pad",
              "position": {
                "x": 150.0,
                "y": 420.0
              },
              "size": {
                "x": 46.0,
                "y": 32.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "hold_gate",
              "movableWhenDrained": false
            },
            {
              "id": "hold_pad",
              "type": "sticky_surface",
              "position": {
                "x": 208.0,
                "y": 390.0
              },
              "size": {
                "x": 36.0,
                "y": 28.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "hold_gate",
              "type": "gate",
              "position": {
                "x": 205.0,
                "y": 300.0
              },
              "size": {
                "x": 30.0,
                "y": 150.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "weight_source",
              "type": "weight",
              "position": {
                "x": 92.0,
                "y": 350.0
              },
              "size": {
                "x": 52.0,
                "y": 40.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "hold_crate",
              "type": "crate",
              "position": {
                "x": 278.0,
                "y": 392.0
              },
              "size": {
                "x": 44.0,
                "y": 44.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "첫 번째 공을 스위치에 남겨 열린 길을 유지해 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "spent_switch_hold",
          "acceptedStrategyIds": [
            "none",
            "spent_switch_hold"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "spent_switch_hold"
          ],
          "optionalChallenges": [
            "previous_ball_switch",
            "single_shot_bypass"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_persistent_03",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 104.0
              },
              "size": {
                "x": 60.0,
                "y": 60.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "sticky_pad",
              "type": "sticky_surface",
              "position": {
                "x": 156.0,
                "y": 382.0
              },
              "size": {
                "x": 94.0,
                "y": 34.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "persistent_03_gate",
              "movableWhenDrained": false
            },
            {
              "id": "elastic_bumper",
              "type": "bumper",
              "position": {
                "x": 244.0,
                "y": 300.0
              },
              "size": {
                "x": 64.0,
                "y": 64.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "persistent_03_gate",
              "type": "gate",
              "position": {
                "x": 282.0,
                "y": 199.0
              },
              "size": {
                "x": 18.0,
                "y": 130.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "persistent_03_gate",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "점착으로 남긴 공을 범퍼처럼 맞혀 홀을 향해 튕겨 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "sticky_ball_bumper",
          "acceptedStrategyIds": [
            "none",
            "sticky_ball_bumper"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "sticky_ball_bumper"
          ],
          "optionalChallenges": [
            "previous_ball_bumper",
            "single_shot_bypass"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_persistent_04",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 180.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 230.0,
                "y": 274.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "stopper_crate",
              "type": "crate",
              "position": {
                "x": 180.0,
                "y": 352.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "stopper_wall",
              "type": "wall",
              "position": {
                "x": 112.0,
                "y": 260.0
              },
              "size": {
                "x": 18.0,
                "y": 180.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "stopper_bumper",
              "type": "bumper",
              "position": {
                "x": 300.0,
                "y": 210.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "p4_bypass_blocker_a",
              "type": "wall",
              "position": {
                "x": 230.0,
                "y": 430.0
              },
              "size": {
                "x": 32.0,
                "y": 110.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "p4_bypass_blocker_b",
              "type": "wall",
              "position": {
                "x": 292.0,
                "y": 330.0
              },
              "size": {
                "x": 22.0,
                "y": 100.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "첫 번째 공과 상자를 함께 스토퍼로 삼아 홀을 열어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "crate_stopper_chain",
          "acceptedStrategyIds": [
            "crate_stopper_chain",
            "none"
          ],
          "solutionFamilies": [
            "crate_stopper_chain",
            "direct_bypass"
          ],
          "optionalChallenges": [
            "previous_ball_stopper",
            "single_shot_bypass"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_chain_score",
      "title": "8. 세 번 이어라",
      "patterns": [
        {
          "patternId": "stage_chain_score_01",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 290.0,
                "y": 360.0
              },
              "size": {
                "x": 88.0,
                "y": 88.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "three_jelly",
              "type": "bumper",
              "position": {
                "x": 200.0,
                "y": 150.0
              },
              "size": {
                "x": 56.0,
                "y": 56.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "three_balloon",
              "type": "balloon",
              "position": {
                "x": 72.0,
                "y": 230.0
              },
              "size": {
                "x": 46.0,
                "y": 46.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "cushion_slider",
              "type": "power_slider",
              "position": {
                "x": 220.0,
                "y": 460.0
              },
              "size": {
                "x": 104.0,
                "y": 42.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 40.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "three_sticky",
              "type": "sticky_surface",
              "position": {
                "x": 204.0,
                "y": 540.0
              },
              "size": {
                "x": 32.0,
                "y": 40.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.94,
              "restitution": 0.12,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "chain_score_01_direct_guard",
              "type": "wall",
              "position": {
                "x": 96.0,
                "y": 462.0
              },
              "size": {
                "x": 18.0,
                "y": 36.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "벽 쿠션과 첫 번째 공을 정해진 순서로 이어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "three_cushion_chain",
          "acceptedStrategyIds": [
            "none",
            "three_cushion_chain"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "three_cushion_chain"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "ordered_cushion_past_ball",
            "previous_ball_chain"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_chain_score_02",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 72.0,
                "y": 132.0
              },
              "size": {
                "x": 80.0,
                "y": 80.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "chain_crate",
              "type": "crate",
              "position": {
                "x": 180.0,
                "y": 245.0
              },
              "size": {
                "x": 72.0,
                "y": 64.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "chain_stone",
              "type": "weight",
              "position": {
                "x": 250.0,
                "y": 80.0
              },
              "size": {
                "x": 52.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "chain_switch",
              "type": "switch_pad",
              "position": {
                "x": 300.0,
                "y": 460.0
              },
              "size": {
                "x": 48.0,
                "y": 32.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "chain_gate",
              "movableWhenDrained": false
            },
            {
              "id": "chain_gate",
              "type": "gate",
              "position": {
                "x": 300.0,
                "y": 160.0
              },
              "size": {
                "x": 24.0,
                "y": 140.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "chain_gate",
              "movableWhenDrained": false
            },
            {
              "id": "chain_score_02_direct_guard",
              "type": "wall",
              "position": {
                "x": 62.0,
                "y": 428.0
              },
              "size": {
                "x": 34.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 1,
          "bonusGoal": "차단벽을 여러 번 튕긴 뒤 첫 번째 공까지 힘을 이어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "multi_wall_past_ball",
          "acceptedStrategyIds": [
            "multi_wall_past_ball",
            "none",
            "switch_gate_route"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "multi_wall_past_ball",
            "switch_gate_route"
          ],
          "optionalChallenges": [
            "multi_wall_chain",
            "optional_gate_route",
            "previous_ball_chain"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_chain_score_03",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 72.0,
                "y": 80.0
              },
              "size": {
                "x": 68.0,
                "y": 68.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "speed_slider",
              "type": "power_slider",
              "position": {
                "x": 125.0,
                "y": 390.0
              },
              "size": {
                "x": 70.0,
                "y": 36.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 44.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "chain_stone",
              "type": "weight",
              "position": {
                "x": 150.0,
                "y": 330.0
              },
              "size": {
                "x": 52.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "bounce_wall",
              "type": "wall",
              "position": {
                "x": 195.0,
                "y": 390.0
              },
              "size": {
                "x": 60.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "chain_jelly",
              "type": "bumper",
              "position": {
                "x": 300.0,
                "y": 440.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "chain_score_03_direct_guard",
              "type": "wall",
              "position": {
                "x": 72.0,
                "y": 160.0
              },
              "size": {
                "x": 72.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "힘 발판에서 돌과 벽, 첫 번째 공까지 충돌 순서를 이어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "slider_stone_wall_past_ball",
          "acceptedStrategyIds": [
            "none",
            "slider_stone_wall_past_ball"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "slider_stone_wall_past_ball"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "power_slider_chain",
            "stone_wall_chain"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_chain_score_04",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "연쇄 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 290.0,
                "y": 100.0
              },
              "size": {
                "x": 88.0,
                "y": 88.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "score_crate",
              "type": "crate",
              "position": {
                "x": 270.0,
                "y": 300.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "score_jelly",
              "type": "bumper",
              "position": {
                "x": 146.5,
                "y": 180.6
              },
              "size": {
                "x": 76.0,
                "y": 76.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "score_balloon",
              "type": "balloon",
              "position": {
                "x": 57.6,
                "y": 297.4
              },
              "size": {
                "x": 64.0,
                "y": 64.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "score_slider",
              "type": "power_slider",
              "position": {
                "x": 280.0,
                "y": 240.0
              },
              "size": {
                "x": 100.0,
                "y": 48.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 42.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "chain_score_04_direct_guard",
              "type": "wall",
              "position": {
                "x": 96.0,
                "y": 423.0
              },
              "size": {
                "x": 18.0,
                "y": 28.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "같은 홀의 짧은 길과 여러 기물을 잇는 긴 길을 비교해 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "wall_object_chain",
          "acceptedStrategyIds": [
            "none",
            "straight_low_chain_high",
            "wall_object_chain"
          ],
          "solutionFamilies": [
            "straight_low_chain_high",
            "wall_object_chain"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "five_object_chain",
            "moving_crate_chain"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_rotating_reflector",
      "title": "9. 판을 돌려 놓아라",
      "patterns": [
        {
          "patternId": "stage_rotating_reflector_01",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "회전 입문",
          "ballSpawn": {
            "x": 60.0,
            "y": 500.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 72.0,
                "y": 110.0
              },
              "size": {
                "x": 56.0,
                "y": 56.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "reflector_a",
              "type": "rotating_reflector",
              "position": {
                "x": 180.0,
                "y": 350.0
              },
              "size": {
                "x": 86.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false,
              "reflectorOrientation": 0,
              "reflectorRotationCount": 0
            },
            {
              "id": "rotation_gate",
              "type": "gate",
              "position": {
                "x": 76.0,
                "y": 238.0
              },
              "size": {
                "x": 104.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "locked",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": "rotation_gate",
              "movableWhenDrained": false
            },
            {
              "id": "guide_stone",
              "type": "weight",
              "position": {
                "x": 270.0,
                "y": 260.0
              },
              "size": {
                "x": 44.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "첫 번째 샷으로 반사판을 한 번 돌린 뒤 다음 샷의 방향을 바꿔 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "rotate_then_shoot",
          "acceptedStrategyIds": [
            "none",
            "rotate_then_shoot"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "single_reflector_prepare"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "one_rotation"
          ],
          "metadata": {
            "baseline": "true"
          }
        },
        {
          "patternId": "stage_rotating_reflector_02",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "순서 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 500.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 110.0
              },
              "size": {
                "x": 56.0,
                "y": 56.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "reflector_a",
              "type": "rotating_reflector",
              "position": {
                "x": 150.0,
                "y": 360.0
              },
              "size": {
                "x": 82.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false,
              "reflectorOrientation": 0,
              "reflectorRotationCount": 0
            },
            {
              "id": "reflector_b",
              "type": "rotating_reflector",
              "position": {
                "x": 250.0,
                "y": 260.0
              },
              "size": {
                "x": 82.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false,
              "reflectorOrientation": 2,
              "reflectorRotationCount": 0
            },
            {
              "id": "order_crate",
              "type": "crate",
              "position": {
                "x": 90.0,
                "y": 250.0
              },
              "size": {
                "x": 48.0,
                "y": 48.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "두 반사판을 차례로 돌리면 다음 샷의 길이 달라집니다.",
          "copyCoreReward": 0,
          "intendedStrategyId": "ordered_reflectors",
          "acceptedStrategyIds": [
            "none",
            "ordered_reflectors"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "two_reflector_order"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "ordered_rotation"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_rotating_reflector_03",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "과거 공 응용",
          "ballSpawn": {
            "x": 60.0,
            "y": 500.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 120.0
              },
              "size": {
                "x": 56.0,
                "y": 56.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "reflector_a",
              "type": "rotating_reflector",
              "position": {
                "x": 100.0,
                "y": 330.0
              },
              "size": {
                "x": 88.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false,
              "reflectorOrientation": 0,
              "reflectorRotationCount": 0
            },
            {
              "id": "rotation_gate",
              "type": "gate",
              "position": {
                "x": 220.0,
                "y": 225.0
              },
              "size": {
                "x": 24.0,
                "y": 150.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "locked",
              "hitboxScale": 0.88,
              "restitution": 0.08,
              "linkId": "rotation_gate",
              "movableWhenDrained": false
            },
            {
              "id": "past_anchor",
              "type": "sticky_surface",
              "position": {
                "x": 70.0,
                "y": 270.0
              },
              "size": {
                "x": 48.0,
                "y": 32.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.94,
              "restitution": 0.12,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "past_bumper",
              "type": "bumper",
              "position": {
                "x": 285.0,
                "y": 350.0
              },
              "size": {
                "x": 54.0,
                "y": 54.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "남겨 둔 첫 공이 반사판을 작동시키는 순서를 찾아 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "past_ball_reflector",
          "acceptedStrategyIds": [
            "none",
            "past_ball_reflector"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "past_ball_activation"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "past_ball_rotation"
          ],
          "metadata": {}
        },
        {
          "patternId": "stage_rotating_reflector_04",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "힘 발판 연계",
          "ballSpawn": {
            "x": 60.0,
            "y": 500.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 120.0
              },
              "size": {
                "x": 56.0,
                "y": 56.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.06,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "power_lane",
              "type": "power_slider",
              "position": {
                "x": 118.0,
                "y": 390.0
              },
              "size": {
                "x": 76.0,
                "y": 36.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 44.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "reflector_a",
              "type": "rotating_reflector",
              "position": {
                "x": 230.0,
                "y": 300.0
              },
              "size": {
                "x": 88.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false,
              "reflectorOrientation": 1,
              "reflectorRotationCount": 0
            },
            {
              "id": "lane_stone",
              "type": "weight",
              "position": {
                "x": 280.0,
                "y": 420.0
              },
              "size": {
                "x": 44.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "힘 발판을 지난 뒤 회전 반사판의 새 방향을 활용해 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "slider_then_reflector",
          "acceptedStrategyIds": [
            "none",
            "slider_then_reflector"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "slider_reflector_chain"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "slider_rotation"
          ],
          "metadata": {}
        }
      ]
    },
    {
      "stageId": "stage_property_shot",
      "title": "10. 속성 한방",
      "patterns": [
        {
          "patternId": "stage_property_shot_a",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "속성 종합",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 72.0,
                "y": 132.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.0,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 24.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 512.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "a_crate",
              "type": "crate",
              "position": {
                "x": 180.0,
                "y": 245.0
              },
              "size": {
                "x": 72.0,
                "y": 64.0
              },
              "traits": [
                "heavy"
              ],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "a_stone",
              "type": "weight",
              "position": {
                "x": 250.0,
                "y": 80.0
              },
              "size": {
                "x": 52.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": true
            },
            {
              "id": "a_switch",
              "type": "switch_pad",
              "position": {
                "x": 250.0,
                "y": 210.0
              },
              "size": {
                "x": 48.0,
                "y": 32.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "a_gate",
              "movableWhenDrained": false
            },
            {
              "id": "a_gate",
              "type": "gate",
              "position": {
                "x": 100.0,
                "y": 185.0
              },
              "size": {
                "x": 128.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "a_gate",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "무거움을 옮긴 뒤 비워진 돌과 상자, 스위치의 변화를 살펴보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "heavy_transfer_switch",
          "acceptedStrategyIds": [
            "heavy_transfer_switch",
            "none"
          ],
          "solutionFamilies": [
            "heavy_transfer_switch",
            "opened_gate_bank"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "drained_weight_push",
            "heavy_crate_switch"
          ],
          "metadata": {
            "baseline": "true",
            "bypassDifficulty": "precision",
            "bypassGrid": "angle±4/power±8",
            "bypassSuccessCeiling": "18",
            "contract": "A"
          }
        },
        {
          "patternId": "stage_property_shot_b",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "속성 종합",
          "ballSpawn": {
            "x": 60.0,
            "y": 500.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 120.0
              },
              "size": {
                "x": 56.0,
                "y": 56.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "b_slider",
              "type": "power_slider",
              "position": {
                "x": 118.0,
                "y": 390.0
              },
              "size": {
                "x": 76.0,
                "y": 36.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": "sequence_gate_b",
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 44.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "b_reflector",
              "type": "rotating_reflector",
              "position": {
                "x": 230.0,
                "y": 300.0
              },
              "size": {
                "x": 88.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false,
              "reflectorOrientation": 1,
              "reflectorRotationCount": 0
            },
            {
              "id": "b_bumper",
              "type": "bumper",
              "position": {
                "x": 260.0,
                "y": 150.0
              },
              "size": {
                "x": 44.0,
                "y": 44.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.08,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "b_stone",
              "type": "weight",
              "position": {
                "x": 280.0,
                "y": 420.0
              },
              "size": {
                "x": 44.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "sequence_gate_b",
              "type": "gate",
              "position": {
                "x": 295.0,
                "y": 185.0
              },
              "size": {
                "x": 70.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "sequence_gate_b",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "슬라이더와 탄성 물체를 거친 뒤 회전판의 새 면을 활용해 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "slider_bouncy_reflector",
          "acceptedStrategyIds": [
            "none",
            "slider_bouncy_reflector"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "slider_reflector_chain"
          ],
          "optionalChallenges": [
            "bouncy_reflection",
            "direct_low_score",
            "precise_direct"
          ],
          "metadata": {
            "contract": "B"
          }
        },
        {
          "patternId": "stage_property_shot_c",
          "weight": 1.0,
          "parShots": 3,
          "difficultyBand": "속성 종합",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 300.0,
                "y": 100.0
              },
              "size": {
                "x": 72.0,
                "y": 72.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 1.1,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "c_crate",
              "type": "crate",
              "position": {
                "x": 270.0,
                "y": 300.0
              },
              "size": {
                "x": 54.0,
                "y": 54.0
              },
              "traits": [],
              "movable": true,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9451851852,
              "restitution": 0.66,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "c_bumper",
              "type": "bumper",
              "position": {
                "x": 146.5,
                "y": 180.6
              },
              "size": {
                "x": 76.0,
                "y": 76.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "c_balloon",
              "type": "balloon",
              "position": {
                "x": 220.0,
                "y": 350.0
              },
              "size": {
                "x": 64.0,
                "y": 64.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.82,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "c_slider",
              "type": "power_slider",
              "position": {
                "x": 280.0,
                "y": 240.0
              },
              "size": {
                "x": 100.0,
                "y": 48.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 42.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "c_direct_blocker",
              "type": "wall",
              "position": {
                "x": 200.0,
                "y": 240.0
              },
              "size": {
                "x": 24.0,
                "y": 60.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 1.0,
              "restitution": 0.64,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "c_sticky",
              "type": "sticky_surface",
              "position": {
                "x": 310.0,
                "y": 500.0
              },
              "size": {
                "x": 32.0,
                "y": 40.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.94,
              "restitution": 0.12,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "c_sticky_target",
              "type": "sticky_surface",
              "position": {
                "x": 180.0,
                "y": 480.0
              },
              "size": {
                "x": 48.0,
                "y": 32.0
              },
              "traits": [
                "sticky"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.94,
              "restitution": 0.12,
              "linkId": "sequence_gate_c",
              "movableWhenDrained": false
            },
            {
              "id": "sequence_gate_c",
              "type": "gate",
              "position": {
                "x": 250.0,
                "y": 170.0
              },
              "size": {
                "x": 100.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "sequence_gate_c",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "점착으로 남긴 과거 공과 풍선, 상자를 여러 샷으로 이어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "sticky_past_ball_chain",
          "acceptedStrategyIds": [
            "none",
            "sticky_past_ball_chain"
          ],
          "solutionFamilies": [
            "opened_gate_bank",
            "sticky_balloon_crate_chain"
          ],
          "optionalChallenges": [
            "balloon_crate_chain",
            "direct_low_score",
            "past_ball_route"
          ],
          "metadata": {
            "contract": "C"
          }
        },
        {
          "patternId": "stage_property_shot_d",
          "weight": 1.0,
          "parShots": 2,
          "difficultyBand": "속성 종합",
          "ballSpawn": {
            "x": 60.0,
            "y": 480.0
          },
          "objects": [
            {
              "id": "hole",
              "type": "hole",
              "position": {
                "x": 72.0,
                "y": 80.0
              },
              "size": {
                "x": 68.0,
                "y": 68.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_top",
              "type": "wall",
              "position": {
                "x": 180.0,
                "y": 12.0
              },
              "size": {
                "x": 340.0,
                "y": 24.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_left",
              "type": "wall",
              "position": {
                "x": 12.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "wall_right",
              "type": "wall",
              "position": {
                "x": 348.0,
                "y": 280.0
              },
              "size": {
                "x": 24.0,
                "y": 520.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "d_setup_slider",
              "type": "power_slider",
              "position": {
                "x": 92.0,
                "y": 390.0
              },
              "size": {
                "x": 16.0,
                "y": 36.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 0.9,
              "restitution": 0.72,
              "linkId": "sequence_gate_d",
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 1.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "d_slider",
              "type": "power_slider",
              "position": {
                "x": 125.0,
                "y": 390.0
              },
              "size": {
                "x": 50.0,
                "y": 27.0
              },
              "traits": [],
              "movable": false,
              "solid": false,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "ready",
              "hitboxScale": 1.2,
              "restitution": 0.72,
              "linkId": null,
              "movableWhenDrained": false,
              "direction": {
                "x": 1.0,
                "y": 0.0
              },
              "referenceSpeed": 44.0,
              "allowedTargets": [
                "ball"
              ]
            },
            {
              "id": "d_stone",
              "type": "weight",
              "position": {
                "x": 150.0,
                "y": 330.0
              },
              "size": {
                "x": 52.0,
                "y": 44.0
              },
              "traits": [
                "heavy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.68,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "d_wall",
              "type": "wall",
              "position": {
                "x": 195.0,
                "y": 390.0
              },
              "size": {
                "x": 60.0,
                "y": 18.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.8,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "d_bumper",
              "type": "bumper",
              "position": {
                "x": 300.0,
                "y": 440.0
              },
              "size": {
                "x": 58.0,
                "y": 58.0
              },
              "traits": [
                "bouncy"
              ],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.92,
              "linkId": null,
              "movableWhenDrained": false
            },
            {
              "id": "sequence_gate_d",
              "type": "gate",
              "position": {
                "x": 180.0,
                "y": 130.0
              },
              "size": {
                "x": 300.0,
                "y": 14.0
              },
              "traits": [],
              "movable": false,
              "solid": true,
              "active": true,
              "open": false,
              "pressed": false,
              "visualState": "",
              "hitboxScale": 0.88,
              "restitution": 0.72,
              "linkId": "sequence_gate_d",
              "movableWhenDrained": false
            }
          ],
          "copyCharges": 0,
          "bonusGoal": "벽과 돌, 슬라이더를 이어 남겨 둔 공까지 한 번에 흔들어 보세요.",
          "copyCoreReward": 0,
          "intendedStrategyId": "slider_stone_past_ball",
          "acceptedStrategyIds": [
            "none",
            "slider_stone_past_ball"
          ],
          "solutionFamilies": [
            "direct_bypass",
            "slider_stone_wall_past_ball"
          ],
          "optionalChallenges": [
            "direct_low_score",
            "high_chain",
            "past_ball_impact"
          ],
          "metadata": {
            "contract": "D"
          }
        }
      ]
    }
  ]
}
''';

final generatedStageCatalog = stageCatalogFromJson(generatedStageCatalogJson);
