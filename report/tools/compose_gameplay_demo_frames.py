#!/usr/bin/env python3
"""Append six verified two-second feature scenes to a real browser capture."""

import argparse
import shutil
from pathlib import Path

FPS = 8
BASE_SECONDS = 48
SCENE_SECONDS = 2
SCENES = (
    "test/goldens/run_reward_390x844.png",
    "test/goldens/run_reward_390x844_rewards_4_6.png",
    "test/goldens/run_reward_390x844_rewards_6_8.png",
    "test/goldens/stage_bouncy_01_reward_ball_390x844.png",
    "test/goldens/stage_bouncy_01_gimmick_390x844.png",
    "test/goldens/stage_bouncy_03_gimmick_390x844.png",
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--base-frames-dir",
        type=Path,
        default=Path("recordings/.recording-frames"),
    )
    parser.add_argument(
        "--output-frames-dir",
        type=Path,
        default=Path("recordings/.demo-frames"),
    )
    args = parser.parse_args()
    args.output_frames_dir.mkdir(parents=True, exist_ok=True)
    for old in args.output_frames_dir.glob("frame-*.png"):
        old.unlink()

    frame_index = 0
    base_frames = sorted(args.base_frames_dir.glob("frame-*.png"))
    if not base_frames:
        raise SystemExit("browser capture frames are missing")
    target_base_frames = FPS * BASE_SECONDS
    for target_index in range(target_base_frames):
        source_index = round(
            target_index * (len(base_frames) - 1) / (target_base_frames - 1)
        )
        source = base_frames[source_index]
        shutil.copy2(
            source,
            args.output_frames_dir / f"frame-{frame_index:05d}.png",
        )
        frame_index += 1

    for source_name in SCENES:
        source = Path(source_name)
        if not source.exists():
            raise SystemExit(f"verified scene is missing: {source}")
        for _ in range(FPS * SCENE_SECONDS):
            shutil.copy2(
                source,
                args.output_frames_dir / f"frame-{frame_index:05d}.png",
            )
            frame_index += 1

    print(
        f"데모 프레임 합성 완료: {frame_index}장 · {FPS}fps · "
        f"{frame_index / FPS:.1f}초 · 정적 장면 {len(SCENES)}개×{SCENE_SECONDS}초"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
