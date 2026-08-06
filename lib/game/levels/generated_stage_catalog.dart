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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
            "wall_reflection",
            "weight_interaction"
          ],
          "optionalChallenges": [
            "무거운 공으로 고정된 무게 물체와 충돌",
            "벽 세 번 반사"
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
            },
            {
              "id": "wall_lane",
              "type": "wall",
              "position": {
                "x": 286.0,
                "y": 430.0
              },
              "size": {
                "x": 104.0,
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
              "linkId": null
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
              "linkId": null
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
                "x": 292.0,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
            },
            {
              "id": "approach_guard",
              "type": "wall",
              "position": {
                "x": 95.0,
                "y": 230.0
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
                "y": 510.0
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
            },
            {
              "id": "jelly",
              "type": "bumper",
              "position": {
                "x": 220.0,
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
              "linkId": null
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
          "patternId": "stage_bouncy_04",
          "weight": 1.0,
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
            "jelly_interaction",
            "wall_reflection"
          ],
          "optionalChallenges": [
            "jelly_hit",
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": "balloon_gate"
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
              "linkId": "balloon_gate"
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": "balloon_gate"
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
              "linkId": "balloon_gate"
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": "balloon_gate"
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
              "linkId": "balloon_gate"
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
          "parShots": 2,
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": "balloon_gate"
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
              "linkId": "balloon_gate"
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
              "linkId": null
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
    }
  ]
}
''';

final generatedStageCatalog = stageCatalogFromJson(generatedStageCatalogJson);
