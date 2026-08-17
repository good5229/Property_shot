#!/usr/bin/env python3
from pathlib import Path

from PIL import Image
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "output/pdf/2026경기게임오디션_게임소개서_김종백.pdf"
W, H = A4

INK = HexColor("#173F43")
TEAL = HexColor("#58C8C7")
DEEP = HexColor("#087E83")
SAND = HexColor("#FFF1C4")
CORAL = HexColor("#FF7861")
MINT = HexColor("#DDF4EC")
PALE = HexColor("#F8FBF4")


def fonts():
    pdfmetrics.registerFont(TTFont("Nanum", ROOT / "assets/fonts/NanumGothic-Regular.ttf"))
    pdfmetrics.registerFont(TTFont("NanumB", ROOT / "assets/fonts/NanumGothic-Bold.ttf"))
    pdfmetrics.registerFont(TTFont("NanumX", ROOT / "assets/fonts/NanumGothic-ExtraBold.ttf"))


def fit_image(c, path, x, y, w, h, crop=False, radius=12):
    path = Path(path)
    with Image.open(path) as im:
        iw, ih = im.size
    if crop:
        scale = max(w / iw, h / ih)
    else:
        scale = min(w / iw, h / ih)
    dw, dh = iw * scale, ih * scale
    dx, dy = x + (w - dw) / 2, y + (h - dh) / 2
    c.saveState()
    clip = c.beginPath()
    clip.roundRect(x, y, w, h, radius)
    c.clipPath(clip, stroke=0, fill=0)
    c.drawImage(str(path), dx, dy, dw, dh, preserveAspectRatio=True, mask="auto")
    c.restoreState()


def bg(c, page, title=None, eyebrow=None):
    c.setFillColor(PALE)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(TEAL)
    c.circle(W - 18, H - 12, 72, fill=1, stroke=0)
    c.setFillColor(SAND)
    c.circle(16, 15, 82, fill=1, stroke=0)
    if eyebrow:
        c.setFillColor(DEEP)
        c.setFont("NanumB", 8.5)
        c.drawString(40, H - 48, eyebrow)
    if title:
        c.setFillColor(INK)
        c.setFont("NanumX", 23)
        c.drawString(40, H - 80, title)
    c.setFillColor(HexColor("#6F817E"))
    c.setFont("Nanum", 7)
    c.drawRightString(W - 34, 22, f"속성 한방 · 팀 김종백   {page:02d}")


def text(c, value, x, y, size=10, font="Nanum", color=INK, max_width=None, leading=None):
    c.setFillColor(color)
    c.setFont(font, size)
    if max_width is None:
        c.drawString(x, y, value)
        return y - (leading or size * 1.5)
    leading = leading or size * 1.55
    line = ""
    lines = []
    for token in value.split(" "):
        trial = token if not line else f"{line} {token}"
        if pdfmetrics.stringWidth(trial, font, size) <= max_width:
            line = trial
        else:
            if line:
                lines.append(line)
            line = token
    if line:
        lines.append(line)
    for line in lines:
        c.drawString(x, y, line)
        y -= leading
    return y


def pill(c, label, x, y, w, fill=MINT, color=INK):
    c.setFillColor(fill)
    c.roundRect(x, y, w, 23, 11, fill=1, stroke=0)
    c.setFillColor(color)
    c.setFont("NanumB", 8)
    c.drawCentredString(x + w / 2, y + 7.5, label)


def card(c, x, y, w, h, title, body, accent=TEAL, icon=None):
    c.setFillColor(white)
    c.roundRect(x, y, w, h, 14, fill=1, stroke=0)
    c.setFillColor(accent)
    c.roundRect(x, y, 7, h, 4, fill=1, stroke=0)
    tx = x + 18
    if icon:
        fit_image(c, ROOT / icon, tx, y + h - 43, 32, 32)
        tx += 42
    c.setFillColor(INK)
    c.setFont("NanumB", 11)
    c.drawString(tx, y + h - 25, title)
    body_x = tx if icon else x + 18
    text(c, body, body_x, y + h - 49, 8.4, max_width=x + w - 18 - body_x, leading=13)


def page_cover(c):
    bg(c, 1)
    c.setFillColor(INK)
    c.setFont("NanumX", 33)
    c.drawString(42, H - 94, "속성 한방")
    c.setFont("NanumB", 14)
    c.setFillColor(DEEP)
    c.drawString(44, H - 122, "속성을 옮겨, 한 번의 발사로 물리 연쇄를 완성하는 퍼즐")
    fit_image(c, ROOT / "assets/generated/island-restoration-world-v1.webp", 52, 255, W - 104, 390)
    pill(c, "캐주얼 물리 퍼즐", 56, 212, 105)
    pill(c, "모바일 · PC Web", 170, 212, 110, fill=SAND)
    pill(c, "10 STAGES · 40 PATTERNS", 290, 212, 155, fill=HexColor("#FFE1D8"))
    c.setFillColor(INK)
    c.setFont("NanumX", 15)
    c.drawString(56, 158, "팀 김종백")
    text(c, "가치 있는 것을 만들어보고자 처음 게임 개발에 도전하는 AI 개발자", 56, 135, 10.5, "NanumB", max_width=W - 112)
    text(c, "기획 · 게임 디자인 · 개발 · 검증", 56, 92, 8.5, color=HexColor("#667B78"))
    c.showPage()


def page_overview(c):
    bg(c, 2, "게임은 이렇게 진행됩니다", "GAME LOOP")
    fit_image(c, ROOT / "test/goldens/game_screen_stage2_390x844.png", 42, 116, 252, 610)
    x = 320
    y = 671
    steps = [
        ("1", "관찰", "스테이지의 물체와 속성을 살핍니다."),
        ("2", "속성 이전", "돌·젤리·뾰족함·점착을 공에 옮깁니다."),
        ("3", "조준과 발사", "방향과 힘을 정하고 한 번에 발사합니다."),
        ("4", "인과 발견", "반사·스위치·풍선·과거 공의 연쇄를 확인합니다."),
        ("5", "다시 시도", "직전 조준과 팁을 비교해 한 가지만 바꿉니다."),
    ]
    for no, title, body in steps:
        c.setFillColor(CORAL if no in ("3", "4") else TEAL)
        c.circle(x + 16, y + 7, 16, fill=1, stroke=0)
        c.setFillColor(white)
        c.setFont("NanumX", 10)
        c.drawCentredString(x + 16, y + 3, no)
        c.setFillColor(INK)
        c.setFont("NanumB", 11)
        c.drawString(x + 43, y + 9, title)
        text(c, body, x + 43, y - 8, 8.2, max_width=205, leading=12)
        y -= 104
    c.showPage()


def page_mechanics(c):
    bg(c, 3, "속성이 규칙을 바꿉니다", "CORE MECHANICS")
    cards = [
        ("무거움", "상자를 밀고 스위치를 눌러 닫힌 길을 엽니다.", "assets/generated/ball-heavy-v1.png", TEAL),
        ("탄성", "벽과 기믹에 부딪힌 뒤에도 반발력을 유지합니다.", "assets/generated/ball-bouncy-v1.png", CORAL),
        ("뾰족함", "풍선을 터뜨려 뒤에 숨은 장치와 길을 드러냅니다.", "assets/generated/ball-sharp-v1.png", HexColor("#F7B84B")),
        ("점착", "공을 원하는 위치에 남겨 다음 샷의 발판으로 만듭니다.", "assets/generated/ball-sticky-v1.png", HexColor("#75A97A")),
    ]
    for i, item in enumerate(cards):
        col, row = i % 2, i // 2
        card(c, 44 + col * 260, 490 - row * 150, 242, 120, item[0], item[1], item[3], item[2])
    c.setFillColor(INK)
    c.setFont("NanumX", 14)
    c.drawString(44, 297, "단순 직선보다 기믹 경로가 유리하도록")
    text(c, "모든 패턴은 의도한 물리 기믹을 활용한 성공 영역이 우회 경로보다 넓도록 검증했습니다. 우회는 가능하더라도 매우 정밀한 입력을 요구합니다.", 44, 272, 9.2, max_width=W - 88, leading=15)
    fit_image(c, ROOT / "test/goldens/generated_gimmick_stage8_768x1024.png", 54, 52, 220, 185, crop=True)
    fit_image(c, ROOT / "test/goldens/generated_gimmick_stage10_768x1024.png", 321, 52, 220, 185, crop=True)
    c.showPage()


def page_progression(c):
    bg(c, 4, "실패해도 발견은 남습니다", "PROGRESSION & MOTIVATION")
    fit_image(c, ROOT / "assets/generated/island-restoration-world-v1.webp", 48, 405, 300, 300)
    card(c, 374, 578, 170, 112, "관측소 복구", "발견 수에 따라 팁과 실험 기능이 열립니다.", TEAL, "assets/generated/island-observatory-v2.png")
    card(c, 374, 448, 170, 112, "등대 복구", "다음 목표와 진행 방향을 더 분명하게 보여줍니다.", CORAL, "assets/generated/island-lighthouse-v2.png")
    card(c, 374, 318, 170, 112, "다리 복구", "새 탐사와 반복 플레이의 길을 연결합니다.", HexColor("#E3A83D"), "assets/generated/island-bridge-v2.png")
    c.setFillColor(INK)
    c.setFont("NanumX", 15)
    c.drawString(48, 356, "클리어만이 진전의 전부가 아닙니다")
    points = [
        "상자를 움직이거나 풍선을 터뜨린 순간도 발견으로 기록",
        "직전 조준 비교와 L1·L2 팁으로 실패를 다음 실험으로 전환",
        "스테이지 클리어 보상은 이후 플레이의 선택지를 확장",
        "10단계 캠페인, 3단계 탐사, 물리 실험실로 플레이 리듬을 분리",
    ]
    y = 326
    for point in points:
        c.setFillColor(TEAL)
        c.circle(54, y + 3, 3.5, fill=1, stroke=0)
        text(c, point, 67, y, 9, "NanumB", max_width=W - 115, leading=14)
        y -= 43
    c.showPage()


def page_content(c):
    bg(c, 5, "짧게 시작하고, 깊게 이어집니다", "CONTENT")
    stages = [
        ("1", "무거움", "stage-icon-heavy-v1.png"),
        ("2", "탄성", "stage-icon-bouncy-v1.png"),
        ("3", "문 열기", "stage-icon-chain-gate-v1.png"),
        ("4", "풍선", "stage-icon-sharp-balloon-v1.png"),
        ("5", "잔류", "stage-icon-persistent-ball-v1.png"),
        ("6", "가속", "stage-icon-speed-slider-v1.png"),
        ("7", "과거 공", "stage-icon-persistent-ball-v1.png"),
        ("8", "연쇄 점수", "stage-icon-chain-score-v1.png"),
        ("9", "회전 반사", "stage-icon-rotating-reflector-v1.png"),
        ("10", "속성 종합", "stage-icon-finale-v1.png"),
    ]
    for i, (no, label, asset) in enumerate(stages):
        col, row = i % 5, i // 5
        x, y = 45 + col * 104, 553 - row * 150
        c.setFillColor(white)
        c.roundRect(x, y, 88, 120, 14, fill=1, stroke=0)
        fit_image(c, ROOT / "assets/generated" / asset, x + 16, y + 42, 56, 56)
        c.setFillColor(DEEP)
        c.setFont("NanumX", 8)
        c.drawString(x + 10, y + 99, no)
        c.setFillColor(INK)
        c.setFont("NanumB", 8.2)
        c.drawCentredString(x + 44, y + 18, label)
    c.setFillColor(INK)
    c.setFont("NanumX", 15)
    c.drawString(46, 340, "각 스테이지는 4개 패턴으로 다시 플레이됩니다")
    text(c, "같은 규칙을 다른 배치와 순서로 다시 해석하도록 10개 스테이지 × 4개 패턴을 구성했습니다. 후반에는 과거 공, 연쇄 점수, 회전 반사판, 복합 속성이 결합됩니다.", 46, 312, 9.3, max_width=W - 92, leading=15)
    fit_image(c, ROOT / "test/goldens/game_screen_stage8_1440x900.png", 48, 70, 235, 205, crop=True)
    fit_image(c, ROOT / "test/goldens/game_screen_stage10_1440x900.png", 313, 70, 235, 205, crop=True)
    c.showPage()


def page_team(c):
    bg(c, 6, "처음이지만, 끝까지 검증했습니다", "TEAM & DEVELOPMENT")
    c.setFillColor(INK)
    c.setFont("NanumX", 20)
    c.drawString(46, 665, "팀 김종백")
    text(c, "가치 있는 것을 만들어보고자 처음 게임 개발에 도전하는 AI 개발자", 46, 630, 12, "NanumB", max_width=W - 92, leading=19)
    cards = [
        ("사람이 정한 것", "게임의 주제, 재미의 기준, 플레이 흐름, 최종 선택과 품질 판단"),
        ("AI로 넓힌 것", "레퍼런스 조사, 구현 후보, 레벨 탐색, 반응형 UI와 테스트 초안"),
        ("코드로 검증한 것", "결정론 물리, 40패턴 기믹 우위, 저장 복구, 접근성, 화면 크기별 회귀"),
    ]
    y = 478
    for i, (title, body) in enumerate(cards):
        card(c, 46, y, W - 92, 105, title, body, [TEAL, CORAL, HexColor("#E3A83D")][i])
        y -= 125
    c.setFillColor(DEEP)
    c.setFont("NanumX", 14)
    c.drawString(46, 92, "목표는 정답을 맞히는 순간보다, 규칙을 알아낸 순간을 기억하게 하는 것입니다.")
    c.showPage()


def main():
    fonts()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUT), pagesize=A4, pageCompression=1)
    c.setTitle("2026 경기게임오디션 게임소개서 · 속성 한방")
    c.setAuthor("팀 김종백")
    for page in [page_cover, page_overview, page_mechanics, page_progression, page_content, page_team]:
        page(c)
    c.save()
    print(OUT)


if __name__ == "__main__":
    main()
