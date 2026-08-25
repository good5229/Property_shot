import json
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

from scripts.build_openai_submission_package import REQUIRED_FILES, build, validate


def _png(width: int = 1920, height: int = 1080) -> bytes:
    return b"\x89PNG\r\n\x1a\n" + b"\x00\x00\x00\rIHDR" + struct.pack(">II", width, height)


class SubmissionPackageTest(unittest.TestCase):
    def _fixture(self, root: Path) -> Path:
        source = root / "source"
        source.mkdir()
        (source / REQUIRED_FILES[0]).write_bytes(_png())
        manifest = {
            "submission": {
                "gameTitle": "속성 한방",
                "teamName": "김종백",
                "gameIntro": "속성을 옮겨 길을 만드는 물리 퍼즐",
                "playUrl": "https://example.com/game/",
            }
        }
        (source / "challenge_period_manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False), encoding="utf-8"
        )
        (source / "submission_fields_ko.md").write_text("공개 제출 문구", encoding="utf-8")
        (source / "validation-summary.json").write_text("{}", encoding="utf-8")
        return source

    def test_builds_reproducible_upload_without_local_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = self._fixture(root)
            first = build(root / "first.zip", source).read_bytes()
            second = build(root / "second.zip", source).read_bytes()
            self.assertEqual(first, second)
            with zipfile.ZipFile(root / "first.zip") as archive:
                self.assertEqual(
                    archive.namelist(), [*REQUIRED_FILES, "SHA256SUMS.txt"]
                )
                self.assertNotIn(b"/Users/", b"".join(archive.read(name) for name in archive.namelist()))

    def test_rejects_oversized_intro_and_local_path(self):
        with tempfile.TemporaryDirectory() as directory:
            source = self._fixture(Path(directory))
            fields_path = source / "challenge_period_manifest.json"
            manifest = json.loads(fields_path.read_text(encoding="utf-8"))
            manifest["submission"]["gameIntro"] = "가" * 201
            fields_path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "1-200"):
                validate(source)

            manifest["submission"]["gameIntro"] = "정상 소개"
            fields_path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
            (source / "submission_fields_ko.md").write_text("/Users/private/file", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "Local path"):
                validate(source)

    def test_rejects_wrong_thumbnail_ratio(self):
        with tempfile.TemporaryDirectory() as directory:
            source = self._fixture(Path(directory))
            (source / REQUIRED_FILES[0]).write_bytes(_png(1920, 1081))
            with self.assertRaisesRegex(ValueError, "1920x1080"):
                validate(source)


if __name__ == "__main__":
    unittest.main()
