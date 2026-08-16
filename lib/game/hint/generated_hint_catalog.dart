// 자동 생성 파일입니다. 직접 편집하지 마세요.
// assets/stages/hints_v1.json에서 결정론적으로 생성됩니다.
// JSON 최상위 field는 version/entries, 생성 API는 generatedHintCatalogJson/generatedHintCatalog입니다.

import 'hint_catalog.dart';

const generatedHintCatalogJson = r'''
{
  "version": 1,
  "entries": [
    {
      "stageId": "stage_heavy",
      "patternId": "stage_heavy_01",
      "hintVersion": 1,
      "intentTags": [
        "heavy",
        "crate_push"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "무거움을 공에 옮긴 뒤 중앙 상자를 밀어 홀 쪽 길을 넓혀 보세요.",
          "intentTags": [
            "heavy",
            "push"
          ],
          "referencedObjectIds": [
            "anvil",
            "crate_a"
          ]
        },
        {
          "level": 2,
          "text": "왼쪽 위의 무거운 돌에서 속성을 가져와 상자의 아래쪽을 밀면 위쪽 길이 열립니다.",
          "intentTags": [
            "transfer",
            "push"
          ],
          "referencedObjectIds": [
            "anvil",
            "crate_a",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_heavy",
      "patternId": "stage_heavy_02",
      "hintVersion": 1,
      "intentTags": [
        "heavy",
        "bank"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "상자만 보지 말고 오른쪽 반사 벽을 먼저 이용해 보세요.",
          "intentTags": [
            "bank"
          ],
          "referencedObjectIds": [
            "reflection_wall_a",
            "reflection_wall_b"
          ]
        },
        {
          "level": 2,
          "text": "무거움을 옮긴 공은 오른쪽 벽에서 튕긴 뒤 상자 쪽으로 돌아올 수 있습니다.",
          "intentTags": [
            "transfer",
            "bank"
          ],
          "referencedObjectIds": [
            "anvil",
            "reflection_wall_a",
            "crate_a"
          ]
        }
      ]
    },
    {
      "stageId": "stage_heavy",
      "patternId": "stage_heavy_03",
      "hintVersion": 1,
      "intentTags": [
        "heavy",
        "lane"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "좁은 통로의 상자를 무거운 공으로 먼저 움직여 보세요.",
          "intentTags": [
            "push"
          ],
          "referencedObjectIds": [
            "crate_b",
            "wall_lane"
          ]
        },
        {
          "level": 2,
          "text": "무거움을 받은 공이 아래 상자보다 먼저 통로 입구의 상자를 건드리면 길이 바뀝니다.",
          "intentTags": [
            "transfer",
            "push"
          ],
          "referencedObjectIds": [
            "anvil",
            "crate_b",
            "wall_lane"
          ]
        }
      ]
    },
    {
      "stageId": "stage_heavy",
      "patternId": "stage_heavy_04",
      "hintVersion": 1,
      "intentTags": [
        "heavy",
        "detour"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "두 우회 벽 사이의 상자를 움직이면 홀로 가는 긴 길이 짧아집니다.",
          "intentTags": [
            "push"
          ],
          "referencedObjectIds": [
            "crate_a",
            "wall_detour_a",
            "wall_detour_b"
          ]
        },
        {
          "level": 2,
          "text": "무거움을 옮긴 공으로 상자를 밀고, 열린 틈을 따라 위쪽으로 보내 보세요.",
          "intentTags": [
            "transfer",
            "push"
          ],
          "referencedObjectIds": [
            "anvil",
            "crate_a",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_bouncy",
      "patternId": "stage_bouncy_01",
      "hintVersion": 1,
      "intentTags": [
        "bouncy",
        "bank",
        "demo"
      ],
      "directClearPolicy": {
        "allowed": false,
        "demoPreferred": true
      },
      "key": {
        "id": "bouncy_01_hint_key",
        "position": {
          "x": 130.0,
          "y": 490.0
        },
        "size": {
          "x": 28.0,
          "y": 28.0
        },
        "version": 1
      },
      "hints": [
        {
          "level": 1,
          "text": "오른쪽 아래 젤리의 탄성을 공에 옮긴 뒤, 홀을 바로 겨냥하지 말고 바닥 반사를 먼저 이용해 보세요.",
          "intentTags": [
            "transfer",
            "bank",
            "bouncy"
          ],
          "referencedObjectIds": [
            "jelly"
          ]
        },
        {
          "level": 2,
          "text": "탄성을 받은 공을 바닥 가까운 방향으로 보내면 중앙 벽을 피해 여러 벽을 튕겨 위쪽 홀로 돌아올 수 있습니다.",
          "intentTags": [
            "transfer",
            "bank",
            "bouncy",
            "redirect"
          ],
          "referencedObjectIds": [
            "jelly",
            "blocker",
            "wall_left",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_bouncy",
      "patternId": "stage_bouncy_02",
      "hintVersion": 1,
      "intentTags": [
        "bouncy",
        "bank"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "왼쪽 벽 반사 뒤 젤리의 옆면을 맞히는 경로를 찾아 보세요.",
          "intentTags": [
            "bank",
            "bouncy"
          ],
          "referencedObjectIds": [
            "wall_left",
            "jelly"
          ]
        },
        {
          "level": 2,
          "text": "중앙 가로벽 아래에서 젤리로 향하면 반사된 공이 위쪽 홀로 돌아갈 수 있습니다.",
          "intentTags": [
            "bank",
            "redirect"
          ],
          "referencedObjectIds": [
            "bank_center_horizontal",
            "jelly",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_bouncy",
      "patternId": "stage_bouncy_03",
      "hintVersion": 1,
      "intentTags": [
        "bouncy",
        "bank"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "세로 막힌 길 때문에 왼쪽 벽 반사와 젤리 반발을 함께 생각해 보세요.",
          "intentTags": [
            "bank",
            "bouncy"
          ],
          "referencedObjectIds": [
            "route_guard_vertical",
            "wall_left",
            "jelly"
          ]
        },
        {
          "level": 2,
          "text": "왼쪽 벽에서 튕긴 공을 젤리 쪽으로 보내면 세로 벽 반대편의 상단 길이 열립니다.",
          "intentTags": [
            "bank",
            "redirect"
          ],
          "referencedObjectIds": [
            "wall_left",
            "jelly",
            "route_guard_vertical"
          ]
        }
      ]
    },
    {
      "stageId": "stage_bouncy",
      "patternId": "stage_bouncy_04",
      "hintVersion": 1,
      "intentTags": [
        "bouncy",
        "bank"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "젤리를 정면으로 치기보다 바닥 반사 뒤 옆면을 이용해 보세요.",
          "intentTags": [
            "bank",
            "bouncy"
          ],
          "referencedObjectIds": [
            "jelly"
          ]
        },
        {
          "level": 2,
          "text": "오른쪽 아래 젤리에서 방향을 바꾼 공은 반대편 상단 홀로 이어질 수 있습니다.",
          "intentTags": [
            "redirect",
            "bouncy"
          ],
          "referencedObjectIds": [
            "jelly",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_gate",
      "patternId": "stage_chain_gate_01",
      "hintVersion": 1,
      "intentTags": [
        "switch",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "문 앞에 바로 가지 말고 스위치를 먼저 눌러 보세요.",
          "intentTags": [
            "switch"
          ],
          "referencedObjectIds": [
            "switch",
            "gate"
          ]
        },
        {
          "level": 2,
          "text": "무거운 돌의 속성을 공에 옮겨 스위치까지 밀어 넣으면 닫힌 문이 열립니다.",
          "intentTags": [
            "transfer",
            "switch"
          ],
          "referencedObjectIds": [
            "steel",
            "switch",
            "gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_gate",
      "patternId": "stage_chain_gate_02",
      "hintVersion": 1,
      "intentTags": [
        "switch",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "홀보다 스위치와 문 사이의 연결을 먼저 확인해 보세요.",
          "intentTags": [
            "switch"
          ],
          "referencedObjectIds": [
            "switch",
            "gate"
          ]
        },
        {
          "level": 2,
          "text": "스위치를 누른 뒤 열린 문 사이로 상자를 피해 공을 보내는 순서가 좋습니다.",
          "intentTags": [
            "switch",
            "route"
          ],
          "referencedObjectIds": [
            "switch",
            "gate",
            "crate_b"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_gate",
      "patternId": "stage_chain_gate_03",
      "hintVersion": 1,
      "intentTags": [
        "switch",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "점착판은 멈춤 지점이고, 문을 여는 대상은 스위치입니다.",
          "intentTags": [
            "switch",
            "sticky"
          ],
          "referencedObjectIds": [
            "glue",
            "switch",
            "gate"
          ]
        },
        {
          "level": 2,
          "text": "공을 점착판에 남기기보다 무거운 돌을 이용해 스위치를 먼저 활성화해 보세요.",
          "intentTags": [
            "transfer",
            "switch"
          ],
          "referencedObjectIds": [
            "glue",
            "steel",
            "switch"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_gate",
      "patternId": "stage_chain_gate_04",
      "hintVersion": 1,
      "intentTags": [
        "switch",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "문을 통과하려면 같은 높이의 스위치를 먼저 건드려야 합니다.",
          "intentTags": [
            "switch"
          ],
          "referencedObjectIds": [
            "switch",
            "gate"
          ]
        },
        {
          "level": 2,
          "text": "스위치를 누른 뒤 상자 옆의 빈 공간으로 공을 보내면 열린 문을 사용할 수 있습니다.",
          "intentTags": [
            "switch",
            "route"
          ],
          "referencedObjectIds": [
            "switch",
            "crate_b",
            "gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_balloon",
      "patternId": "stage_balloon_01",
      "hintVersion": 1,
      "intentTags": [
        "sharp",
        "balloon"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "풍선을 피하지 말고 뾰족함을 옮긴 공으로 터뜨릴 수 있습니다.",
          "intentTags": [
            "transfer",
            "pop"
          ],
          "referencedObjectIds": [
            "spike_source",
            "balloon"
          ]
        },
        {
          "level": 2,
          "text": "뾰족함을 받은 공이 풍선과 문 사이를 지나면 스위치 쪽 길이 달라집니다.",
          "intentTags": [
            "transfer",
            "pop"
          ],
          "referencedObjectIds": [
            "spike_source",
            "balloon",
            "balloon_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_balloon",
      "patternId": "stage_balloon_02",
      "hintVersion": 1,
      "intentTags": [
        "sharp",
        "balloon"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "풍선은 막는 물체이면서 튕김을 만드는 쿠션이기도 합니다.",
          "intentTags": [
            "balloon",
            "bank"
          ],
          "referencedObjectIds": [
            "balloon"
          ]
        },
        {
          "level": 2,
          "text": "뾰족함으로 풍선을 터뜨리거나, 그대로 반사시켜 문 옆 길을 이용해 보세요.",
          "intentTags": [
            "pop",
            "bank"
          ],
          "referencedObjectIds": [
            "spike_source",
            "balloon",
            "balloon_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_balloon",
      "patternId": "stage_balloon_03",
      "hintVersion": 1,
      "intentTags": [
        "sharp",
        "balloon"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "왼쪽 가까운 홀을 향하기 전 풍선과 스위치의 관계를 확인해 보세요.",
          "intentTags": [
            "switch",
            "balloon"
          ],
          "referencedObjectIds": [
            "balloon",
            "balloon_switch"
          ]
        },
        {
          "level": 2,
          "text": "뾰족함을 옮긴 공이 풍선을 터뜨리면 상자와 문 사이의 길을 바꿀 수 있습니다.",
          "intentTags": [
            "transfer",
            "pop"
          ],
          "referencedObjectIds": [
            "spike_source",
            "balloon",
            "balloon_crate",
            "balloon_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_balloon",
      "patternId": "stage_balloon_04",
      "hintVersion": 1,
      "intentTags": [
        "sharp",
        "balloon"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "풍선이 둘이면 먼저 어느 풍선이 길을 가로막는지 구분해 보세요.",
          "intentTags": [
            "balloon",
            "route"
          ],
          "referencedObjectIds": [
            "balloon",
            "balloon_b"
          ]
        },
        {
          "level": 2,
          "text": "뾰족함으로 위쪽 풍선을 정리한 뒤 남은 풍선을 쿠션처럼 쓰면 문 쪽으로 연결됩니다.",
          "intentTags": [
            "transfer",
            "pop",
            "bank"
          ],
          "referencedObjectIds": [
            "spike_source",
            "balloon",
            "balloon_b",
            "balloon_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_drained",
      "patternId": "stage_drained_01",
      "hintVersion": 1,
      "intentTags": [
        "drain",
        "weight"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "무거운 돌에서 속성을 빼면 돌 자체도 움직일 수 있습니다.",
          "intentTags": [
            "drain",
            "push"
          ],
          "referencedObjectIds": [
            "drain_weight",
            "weight_route_ball"
          ]
        },
        {
          "level": 2,
          "text": "무거움을 공으로 가져온 뒤 가벼워진 돌을 밀면 중앙 공과 홀 사이가 이어집니다.",
          "intentTags": [
            "drain",
            "push"
          ],
          "referencedObjectIds": [
            "drain_weight",
            "weight_route_ball",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_drained",
      "patternId": "stage_drained_02",
      "hintVersion": 1,
      "intentTags": [
        "drain",
        "bouncy"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "젤리의 탄성을 가져오면 원래 젤리가 움직일 수 있는 통로가 생깁니다.",
          "intentTags": [
            "drain",
            "route"
          ],
          "referencedObjectIds": [
            "drain_jelly",
            "lane_crate"
          ]
        },
        {
          "level": 2,
          "text": "탄성을 공에 옮긴 뒤 가벼워진 젤리 옆의 상자를 지나 왼쪽 홀을 노려 보세요.",
          "intentTags": [
            "drain",
            "bank"
          ],
          "referencedObjectIds": [
            "drain_jelly",
            "lane_crate",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_drained",
      "patternId": "stage_drained_03",
      "hintVersion": 1,
      "intentTags": [
        "drain",
        "sticky"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "점착 속성을 가져오면 점착판이 고정물만은 아니게 됩니다.",
          "intentTags": [
            "drain",
            "sticky"
          ],
          "referencedObjectIds": [
            "drain_glue",
            "glue_route_ball"
          ]
        },
        {
          "level": 2,
          "text": "점착을 공으로 옮겨 가벼워진 점착판 주변을 건드리면 중앙 세로 길이 달라집니다.",
          "intentTags": [
            "drain",
            "route"
          ],
          "referencedObjectIds": [
            "drain_glue",
            "glue_route_ball",
            "bypass_crate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_drained",
      "patternId": "stage_drained_04",
      "hintVersion": 1,
      "intentTags": [
        "drain",
        "choice"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "두 속성 원본 중 하나를 비우면 가운데 상자 주변의 선택지가 달라집니다.",
          "intentTags": [
            "drain",
            "choice"
          ],
          "referencedObjectIds": [
            "drain_weight_choice",
            "drain_jelly_choice",
            "choice_crate"
          ]
        },
        {
          "level": 2,
          "text": "무거운 돌을 비우면 왼쪽 밀기 길이, 젤리를 비우면 오른쪽 튕김 길이를 만들 수 있습니다.",
          "intentTags": [
            "drain",
            "choice"
          ],
          "referencedObjectIds": [
            "drain_weight_choice",
            "drain_jelly_choice"
          ]
        }
      ]
    },
    {
      "stageId": "stage_speed",
      "patternId": "stage_speed_01",
      "hintVersion": 1,
      "intentTags": [
        "slider",
        "speed"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "마지막 속도 발판을 지나야 공이 홀 앞에서 멈추지 않습니다.",
          "intentTags": [
            "slider"
          ],
          "referencedObjectIds": [
            "last_slider",
            "hole"
          ]
        },
        {
          "level": 2,
          "text": "조용한 상자를 피해 마지막 발판을 통과한 뒤 홀로 들어가는 길을 찾아 보세요.",
          "intentTags": [
            "slider",
            "route"
          ],
          "referencedObjectIds": [
            "quiet_crate",
            "last_slider",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_speed",
      "patternId": "stage_speed_02",
      "hintVersion": 1,
      "intentTags": [
        "slider",
        "bank"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "속도 발판에 바로 가기보다 먼저 반사 벽을 이용해 보세요.",
          "intentTags": [
            "bank",
            "slider"
          ],
          "referencedObjectIds": [
            "bank_wall",
            "after_bank_slider"
          ]
        },
        {
          "level": 2,
          "text": "반사 벽에서 튕긴 공이 발판을 통과하면 오른쪽 위 홀까지 속도가 이어집니다.",
          "intentTags": [
            "bank",
            "slider"
          ],
          "referencedObjectIds": [
            "bank_wall",
            "after_bank_slider",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_speed",
      "patternId": "stage_speed_03",
      "hintVersion": 1,
      "intentTags": [
        "slider",
        "push"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "상자를 밀어 발판과 공이 만나는 위치를 바꿔 보세요.",
          "intentTags": [
            "push",
            "slider"
          ],
          "referencedObjectIds": [
            "push_crate",
            "crate_slider"
          ]
        },
        {
          "level": 2,
          "text": "상자가 발판 근처로 움직인 뒤 그 상자를 다시 치면 속도 발판을 지나 홀 쪽으로 갑니다.",
          "intentTags": [
            "push",
            "slider"
          ],
          "referencedObjectIds": [
            "push_crate",
            "crate_slider",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_speed",
      "patternId": "stage_speed_04",
      "hintVersion": 1,
      "intentTags": [
        "slider",
        "choice"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "두 속도 발판은 같은 결과를 내지 않습니다. 홀 쪽으로 향하는 쪽을 골라 보세요.",
          "intentTags": [
            "slider",
            "choice"
          ],
          "referencedObjectIds": [
            "left_slider",
            "right_slider"
          ]
        },
        {
          "level": 2,
          "text": "가운데 상자를 피해 오른쪽 발판을 지나면 위쪽 홀을 향하는 속도를 얻습니다.",
          "intentTags": [
            "slider",
            "route"
          ],
          "referencedObjectIds": [
            "choice_crate",
            "right_slider",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_persistent",
      "patternId": "stage_persistent_01",
      "hintVersion": 1,
      "intentTags": [
        "past_ball",
        "switch",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": false
      },
      "hints": [
        {
          "level": 1,
          "text": "첫 공으로 아래쪽의 작은 스위치를 눌러 문을 먼저 열어 보세요.",
          "intentTags": [
            "switch",
            "gate"
          ],
          "referencedObjectIds": [
            "sequence_switch_p1",
            "p1_setup_gate"
          ]
        },
        {
          "level": 2,
          "text": "문이 열린 뒤 첫 공을 쿠션처럼 남기고, 두 번째 공을 그 공 쪽으로 보내면 홀 방향으로 바뀝니다.",
          "intentTags": [
            "past_ball",
            "switch",
            "bank"
          ],
          "referencedObjectIds": [
            "sequence_switch_p1",
            "p1_setup_gate",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_persistent",
      "patternId": "stage_persistent_02",
      "hintVersion": 1,
      "intentTags": [
        "past_ball",
        "switch"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "첫 공을 스위치 위에 남겨 문을 계속 열어 둘 수 있습니다.",
          "intentTags": [
            "past_ball",
            "switch"
          ],
          "referencedObjectIds": [
            "switch_hold",
            "hold_gate"
          ]
        },
        {
          "level": 2,
          "text": "무거움을 이용해 첫 공을 스위치에 고정한 뒤 열린 문 사이로 다음 공을 보내 보세요.",
          "intentTags": [
            "transfer",
            "past_ball",
            "switch"
          ],
          "referencedObjectIds": [
            "weight_source",
            "switch_hold",
            "hold_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_persistent",
      "patternId": "stage_persistent_03",
      "hintVersion": 1,
      "intentTags": [
        "past_ball",
        "sticky"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "점착판에 첫 공을 남기면 두 번째 공의 튕김 지점이 됩니다.",
          "intentTags": [
            "past_ball",
            "sticky"
          ],
          "referencedObjectIds": [
            "sticky_pad",
            "elastic_bumper"
          ]
        },
        {
          "level": 2,
          "text": "점착 속성으로 첫 공을 고정한 뒤 젤리와 그 공 사이를 이용해 홀 쪽으로 보내세요.",
          "intentTags": [
            "transfer",
            "past_ball",
            "bank"
          ],
          "referencedObjectIds": [
            "sticky_pad",
            "elastic_bumper",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_persistent",
      "patternId": "stage_persistent_04",
      "hintVersion": 1,
      "intentTags": [
        "past_ball",
        "crate"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "첫 공을 상자 근처에 남기면 다음 공이 멈출 자리를 만들 수 있습니다.",
          "intentTags": [
            "past_ball",
            "cushion"
          ],
          "referencedObjectIds": [
            "stopper_crate",
            "stopper_wall"
          ]
        },
        {
          "level": 2,
          "text": "상자에서 멈춘 첫 공을 두 번째 공이 건드리게 하면 젤리 반사 뒤 홀 쪽으로 이어집니다.",
          "intentTags": [
            "past_ball",
            "bank"
          ],
          "referencedObjectIds": [
            "stopper_crate",
            "stopper_bumper",
            "hole"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_score",
      "patternId": "stage_chain_score_01",
      "hintVersion": 1,
      "intentTags": [
        "chain",
        "past_ball"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "낮은 점수의 직행보다 첫 공을 쿠션으로 남기는 연쇄를 노려 보세요.",
          "intentTags": [
            "chain",
            "past_ball"
          ],
          "referencedObjectIds": [
            "three_jelly",
            "cushion_slider"
          ]
        },
        {
          "level": 2,
          "text": "벽과 바닥에서 여러 번 튕긴 첫 공을 두 번째 공이 이용하면 속도 발판까지 연결됩니다.",
          "intentTags": [
            "chain",
            "bank",
            "slider"
          ],
          "referencedObjectIds": [
            "wall_left",
            "cushion_slider",
            "three_jelly"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_score",
      "patternId": "stage_chain_score_02",
      "hintVersion": 1,
      "intentTags": [
        "chain",
        "bank"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "첫 공을 위쪽 벽 가까이에 남겨 두 번째 공의 쿠션으로 써 보세요.",
          "intentTags": [
            "chain",
            "past_ball"
          ],
          "referencedObjectIds": [
            "wall_left",
            "wall_right"
          ]
        },
        {
          "level": 2,
          "text": "두 번째 공을 아래 경계와 짧은 차단벽에 연속으로 튕긴 뒤 남은 첫 공을 맞혀 보세요.",
          "intentTags": [
            "chain",
            "past_ball",
            "bank"
          ],
          "referencedObjectIds": [
            "chain_score_02_direct_guard",
            "wall_left"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_score",
      "patternId": "stage_chain_score_03",
      "hintVersion": 1,
      "intentTags": [
        "chain",
        "slider"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "속도 발판은 돌과 벽을 거친 뒤의 공을 더 멀리 보낼 수 있습니다.",
          "intentTags": [
            "chain",
            "slider"
          ],
          "referencedObjectIds": [
            "speed_slider",
            "chain_stone",
            "bounce_wall"
          ]
        },
        {
          "level": 2,
          "text": "첫 공을 남겨 두고 두 번째 공이 발판, 돌, 반사 벽 순서로 지나게 하면 연쇄 점수가 커집니다.",
          "intentTags": [
            "chain",
            "past_ball",
            "slider"
          ],
          "referencedObjectIds": [
            "speed_slider",
            "chain_stone",
            "bounce_wall"
          ]
        }
      ]
    },
    {
      "stageId": "stage_chain_score",
      "patternId": "stage_chain_score_04",
      "hintVersion": 1,
      "intentTags": [
        "chain",
        "slider"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "상자와 젤리 사이에 첫 공을 남기면 두 번째 샷의 연쇄가 길어집니다.",
          "intentTags": [
            "chain",
            "past_ball"
          ],
          "referencedObjectIds": [
            "score_crate",
            "score_jelly"
          ]
        },
        {
          "level": 2,
          "text": "벽 반사 뒤 상자, 젤리, 속도 발판을 차례로 지나도록 첫 공을 쿠션으로 써 보세요.",
          "intentTags": [
            "chain",
            "bank",
            "slider"
          ],
          "referencedObjectIds": [
            "score_crate",
            "score_jelly",
            "score_slider"
          ]
        }
      ]
    },
    {
      "stageId": "stage_rotating_reflector",
      "patternId": "stage_rotating_reflector_01",
      "hintVersion": 1,
      "intentTags": [
        "reflector",
        "rotate"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "반사판은 한 번 맞힐 때마다 방향이 바뀌므로 먼저 돌려 놓을 수 있습니다.",
          "intentTags": [
            "reflector",
            "rotate"
          ],
          "referencedObjectIds": [
            "reflector_a"
          ]
        },
        {
          "level": 2,
          "text": "첫 공으로 반사판을 돌려 문을 연 뒤 다음 공을 반사판에 다시 보내 보세요.",
          "intentTags": [
            "rotate",
            "gate",
            "past_ball"
          ],
          "referencedObjectIds": [
            "reflector_a",
            "rotation_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_rotating_reflector",
      "patternId": "stage_rotating_reflector_02",
      "hintVersion": 1,
      "intentTags": [
        "reflector",
        "order"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "두 반사판의 방향을 같은 샷에서 바꾸려 하지 말고 순서를 나눠 보세요.",
          "intentTags": [
            "reflector",
            "order"
          ],
          "referencedObjectIds": [
            "reflector_a",
            "reflector_b"
          ]
        },
        {
          "level": 2,
          "text": "첫 반사판을 먼저 돌린 뒤 두 번째 반사판을 향하면 상자 옆 경로가 달라집니다.",
          "intentTags": [
            "reflector",
            "order"
          ],
          "referencedObjectIds": [
            "reflector_a",
            "reflector_b",
            "order_crate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_rotating_reflector",
      "patternId": "stage_rotating_reflector_03",
      "hintVersion": 1,
      "intentTags": [
        "reflector",
        "past_ball"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "반사판을 돌린 첫 공은 사라지지 않아 다음 반사의 쿠션이 됩니다.",
          "intentTags": [
            "reflector",
            "past_ball"
          ],
          "referencedObjectIds": [
            "reflector_a",
            "past_anchor"
          ]
        },
        {
          "level": 2,
          "text": "첫 공으로 문을 열고 반사판 방향을 바꾼 뒤, 남은 공과 젤리를 함께 이용해 보세요.",
          "intentTags": [
            "rotate",
            "past_ball",
            "gate"
          ],
          "referencedObjectIds": [
            "reflector_a",
            "rotation_gate",
            "past_bumper"
          ]
        }
      ]
    },
    {
      "stageId": "stage_rotating_reflector",
      "patternId": "stage_rotating_reflector_04",
      "hintVersion": 1,
      "intentTags": [
        "reflector",
        "slider"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "속도 발판을 지난 공이 반사판에 닿으면 방향 변화가 더 눈에 띕니다.",
          "intentTags": [
            "slider",
            "reflector"
          ],
          "referencedObjectIds": [
            "power_lane",
            "reflector_a"
          ]
        },
        {
          "level": 2,
          "text": "발판으로 속도를 얻은 뒤 반사판을 돌리고 돌 옆의 상단 길을 노려 보세요.",
          "intentTags": [
            "slider",
            "rotate",
            "route"
          ],
          "referencedObjectIds": [
            "power_lane",
            "reflector_a",
            "lane_stone"
          ]
        }
      ]
    },
    {
      "stageId": "stage_property_shot",
      "patternId": "stage_property_shot_a",
      "hintVersion": 1,
      "intentTags": [
        "heavy",
        "switch",
        "chain"
      ],
      "directClearPolicy": {
        "allowed": false
      },
      "hints": [
        {
          "level": 1,
          "text": "무거움을 옮긴 첫 공으로 상자와 스위치를 함께 움직일 수 있습니다.",
          "intentTags": [
            "transfer",
            "push",
            "switch"
          ],
          "referencedObjectIds": [
            "a_stone",
            "a_crate",
            "a_switch"
          ]
        },
        {
          "level": 2,
          "text": "상자를 민 공이 스위치를 누르면 문이 열리고 다음 공이 홀로 갈 수 있습니다.",
          "intentTags": [
            "push",
            "switch",
            "gate"
          ],
          "referencedObjectIds": [
            "a_crate",
            "a_switch",
            "a_gate"
          ]
        }
      ]
    },
    {
      "stageId": "stage_property_shot",
      "patternId": "stage_property_shot_b",
      "hintVersion": 1,
      "intentTags": [
        "slider",
        "reflector",
        "bouncy"
      ],
      "directClearPolicy": {
        "allowed": true
      },
      "hints": [
        {
          "level": 1,
          "text": "속도 발판과 회전 반사판을 한 경로에 연결해 보세요.",
          "intentTags": [
            "slider",
            "reflector"
          ],
          "referencedObjectIds": [
            "b_slider",
            "b_reflector"
          ]
        },
        {
          "level": 2,
          "text": "발판을 지난 공이 반사판을 돌린 뒤 젤리에 닿으면 홀 쪽으로 방향이 이어집니다.",
          "intentTags": [
            "slider",
            "rotate",
            "bouncy"
          ],
          "referencedObjectIds": [
            "b_slider",
            "b_reflector",
            "b_bumper"
          ]
        }
      ]
    },
    {
      "stageId": "stage_property_shot",
      "patternId": "stage_property_shot_c",
      "hintVersion": 1,
      "intentTags": [
        "sticky",
        "past_ball",
        "balloon",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": false
      },
      "hints": [
        {
          "level": 1,
          "text": "점착 속성을 옮긴 첫 공을 아래 점착판에 남겨 문을 먼저 열어 보세요.",
          "intentTags": [
            "transfer",
            "sticky",
            "gate"
          ],
          "referencedObjectIds": [
            "c_sticky",
            "c_sticky_target",
            "sequence_gate_c"
          ]
        },
        {
          "level": 2,
          "text": "문이 열린 뒤 남은 첫 공을 두 번째 공이 건드리고 상자와 풍선을 차례로 이용해 보세요.",
          "intentTags": [
            "past_ball",
            "push",
            "balloon",
            "gate"
          ],
          "referencedObjectIds": [
            "c_crate",
            "c_balloon",
            "c_sticky_target",
            "sequence_gate_c"
          ]
        }
      ]
    },
    {
      "stageId": "stage_property_shot",
      "patternId": "stage_property_shot_d",
      "hintVersion": 1,
      "intentTags": [
        "slider",
        "past_ball",
        "stone",
        "gate"
      ],
      "directClearPolicy": {
        "allowed": false
      },
      "hints": [
        {
          "level": 1,
          "text": "첫 공을 왼쪽 시작 발판에 스치게 해 문을 열고 공을 남겨 보세요.",
          "intentTags": [
            "slider",
            "past_ball",
            "gate"
          ],
          "referencedObjectIds": [
            "d_setup_slider",
            "sequence_gate_d"
          ]
        },
        {
          "level": 2,
          "text": "문이 열린 뒤 두 번째 공을 발판과 돌에서 방향을 바꿔 남은 공 쪽으로 보내세요.",
          "intentTags": [
            "past_ball",
            "slider",
            "push",
            "gate"
          ],
          "referencedObjectIds": [
            "d_slider",
            "d_stone",
            "d_bumper",
            "sequence_gate_d"
          ]
        }
      ]
    }
  ]
}
''';

final generatedHintCatalog = HintCatalog.fromJsonString(generatedHintCatalogJson);
