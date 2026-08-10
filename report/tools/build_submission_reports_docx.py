#!/usr/bin/env python3
"""Build the two submission DOCX files from their Markdown sources.

The game guide uses the documents skill's compact_reference_guide preset.
The AI report uses standard_business_brief. Both use editorial_cover and a
named Korean-font override: embedded NanumGothic replaces Calibri so Hangul
renders consistently in LibreOffice and the final PDF.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from PIL import Image as PILImage

import build_final_report_docx as base


ROOT = Path(__file__).resolve().parents[2]
FONT = base.FONT
BLUE = base.BLUE
DARK_BLUE = base.DARK_BLUE
NAVY = base.NAVY
MUTED = base.MUTED
GOLD = base.GOLD
DOCUMENT_LANGUAGE = "ko-KR"


@dataclass(frozen=True)
class ReportConfig:
    source: Path
    output: Path
    title: str
    subtitle: str
    kicker: str
    running_label: str
    preset: str
    header_fill: str


def set_document_language(doc: Document) -> None:
    """Declare Korean as the document and inherited text language."""

    doc.core_properties.language = DOCUMENT_LANGUAGE
    settings = doc.settings._element
    theme_lang = settings.find(qn("w:themeFontLang"))
    if theme_lang is None:
        theme_lang = OxmlElement("w:themeFontLang")
        settings.append(theme_lang)
    theme_lang.set(qn("w:val"), DOCUMENT_LANGUAGE)
    theme_lang.set(qn("w:eastAsia"), DOCUMENT_LANGUAGE)

    for style in doc.styles:
        rpr = style._element.get_or_add_rPr()
        lang = rpr.find(qn("w:lang"))
        if lang is None:
            lang = OxmlElement("w:lang")
            rpr.append(lang)
        lang.set(qn("w:val"), DOCUMENT_LANGUAGE)
        lang.set(qn("w:eastAsia"), DOCUMENT_LANGUAGE)


CONFIGS = {
    "game": ReportConfig(
        source=ROOT / "report" / "game_introduction.md",
        output=ROOT / "report" / "dist" / "property_shot_game_guide.docx",
        title="속성 한방(Property Shot)",
        subtitle="게임 소개 및 설명",
        kicker="Game Guide",
        running_label="Property Shot · Game Guide",
        preset="compact_reference_guide",
        header_fill="E8EEF5",
    ),
    "ai": ReportConfig(
        source=ROOT / "report" / "ai_technical_report.md",
        output=ROOT / "report" / "dist" / "property_shot_ai_technical_report.docx",
        title="속성 한방(Property Shot)",
        subtitle="AI 활용 기술 문서",
        kicker="AI Technical Report",
        running_label="Property Shot · AI Technical Report",
        preset="standard_business_brief",
        header_fill="F2F4F7",
    ),
}


def configure_styles(doc: Document, config: ReportConfig) -> dict[str, float]:
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    if config.preset == "compact_reference_guide":
        tokens = {
            "body_after": 6,
            "body_line": 1.25,
            "h1_before": 18,
            "h1_after": 10,
            "h2_before": 14,
            "h2_after": 7,
            "h3_before": 10,
            "h3_after": 5,
            "list_left": 0.375,
            "list_hanging": 0.188,
            "list_after": 4,
            "list_line": 1.25,
        }
    else:
        tokens = {
            "body_after": 6,
            "body_line": 1.10,
            "h1_before": 16,
            "h1_after": 8,
            "h2_before": 12,
            "h2_after": 6,
            "h3_before": 8,
            "h3_after": 4,
            "list_left": 0.5,
            "list_hanging": 0.25,
            "list_after": 8,
            "list_line": 1.167,
        }

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = FONT
    for key in ("ascii", "hAnsi", "eastAsia", "cs"):
        normal._element.rPr.rFonts.set(qn(f"w:{key}"), FONT)
    normal._element.rPr.rFonts.set(qn("w:hint"), "eastAsia")
    normal.font.size = Pt(11)
    normal.paragraph_format.space_before = Pt(0)
    normal.paragraph_format.space_after = Pt(tokens["body_after"])
    normal.paragraph_format.line_spacing = tokens["body_line"]
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT

    headings = [
        ("Heading 1", 16, BLUE, tokens["h1_before"], tokens["h1_after"]),
        ("Heading 2", 13, BLUE, tokens["h2_before"], tokens["h2_after"]),
        ("Heading 3", 12, DARK_BLUE, tokens["h3_before"], tokens["h3_after"]),
    ]
    for name, size, color, before, after in headings:
        style = styles[name]
        style.font.name = FONT
        for key in ("ascii", "hAnsi", "eastAsia", "cs"):
            style._element.rPr.rFonts.set(qn(f"w:{key}"), FONT)
        style._element.rPr.rFonts.set(qn("w:hint"), "eastAsia")
        style.font.size = Pt(size)
        style.font.color.rgb = color
        style.font.bold = True
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
    return tokens


def add_page_field(paragraph) -> None:
    run = paragraph.add_run("Page ")
    base.set_run_font(run, size=8.5, color=MUTED)
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.append(begin)
    run._r.append(instr)
    run._r.append(end)


def add_cover(doc: Document, config: ReportConfig) -> None:
    section = doc.sections[0]
    section.different_first_page_header_footer = True

    header = section.header
    hp = header.paragraphs[0]
    hp.text = ""
    hr = hp.add_run(config.running_label)
    base.set_run_font(hr, size=9, color=MUTED)
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    base.paragraph_bottom_border(hp, "D7DBE2", "6")

    footer = section.footer
    fp = footer.paragraphs[0]
    fp.text = ""
    fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    fr = fp.add_run(config.running_label + " · ")
    base.set_run_font(fr, size=8.5, color=MUTED)
    add_page_field(fp)

    for _ in range(5):
        doc.add_paragraph()
    kicker = doc.add_paragraph()
    kicker.alignment = WD_ALIGN_PARAGRAPH.CENTER
    kicker.paragraph_format.space_after = Pt(18)
    base.set_run_font(kicker.add_run(config.kicker), size=11, color=GOLD, bold=True)

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    title.paragraph_format.space_after = Pt(8)
    base.set_run_font(title.add_run(config.title), size=30, color=NAVY, bold=True)

    subtitle = doc.add_paragraph()
    subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
    subtitle.paragraph_format.space_after = Pt(28)
    base.set_run_font(subtitle.add_run(config.subtitle), size=15, color=DARK_BLUE)

    strap = doc.add_paragraph()
    strap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    strap.paragraph_format.space_after = Pt(72)
    base.set_run_font(
        strap.add_run("속성을 옮기고, 장면의 상태를 설계하는 세로형 물리 퍼즐"),
        size=10.5,
        color=GOLD,
    )

    meta = doc.add_paragraph()
    meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    meta.paragraph_format.space_after = Pt(6)
    base.set_run_font(meta.add_run("2026-08-10 KST"), size=11, color=NAVY, bold=True)

    commit = doc.add_paragraph()
    commit.alignment = WD_ALIGN_PARAGRAPH.CENTER
    commit.paragraph_format.space_after = Pt(10)
    base.set_run_font(
        commit.add_run("기능 기준 main 작업 트리 · base bfb7a39734cad39b"),
        size=8.5,
        color=MUTED,
    )

    play = doc.add_paragraph()
    play.alignment = WD_ALIGN_PARAGRAPH.CENTER
    base.add_hyperlink(
        play,
        "good5229.github.io/Property_shot/",
        "https://good5229.github.io/Property_shot/",
        bold=True,
    )
    doc.add_page_break()


def next_num_id(doc: Document) -> int:
    root = doc.part.numbering_part.element
    values = [int(node.get(qn("w:numId"))) for node in root.findall(qn("w:num"))]
    return max(values, default=0) + 1


def add_numbering(doc: Document, *, bullet: bool, tokens: dict[str, float]) -> int:
    root = doc.part.numbering_part.element
    num_id = next_num_id(doc)
    abstract_id = num_id + 100

    abstract = OxmlElement("w:abstractNum")
    abstract.set(qn("w:abstractNumId"), str(abstract_id))
    multi = OxmlElement("w:multiLevelType")
    multi.set(qn("w:val"), "singleLevel")
    abstract.append(multi)
    lvl = OxmlElement("w:lvl")
    lvl.set(qn("w:ilvl"), "0")
    start = OxmlElement("w:start")
    start.set(qn("w:val"), "1")
    lvl.append(start)
    num_fmt = OxmlElement("w:numFmt")
    num_fmt.set(qn("w:val"), "bullet" if bullet else "decimal")
    lvl.append(num_fmt)
    lvl_text = OxmlElement("w:lvlText")
    lvl_text.set(qn("w:val"), "•" if bullet else "%1.")
    lvl.append(lvl_text)
    suff = OxmlElement("w:suff")
    suff.set(qn("w:val"), "tab")
    lvl.append(suff)
    ppr = OxmlElement("w:pPr")
    tabs = OxmlElement("w:tabs")
    tab = OxmlElement("w:tab")
    tab.set(qn("w:val"), "num")
    tab.set(qn("w:pos"), str(round(tokens["list_left"] * 1440)))
    tabs.append(tab)
    ppr.append(tabs)
    ind = OxmlElement("w:ind")
    ind.set(qn("w:left"), str(round(tokens["list_left"] * 1440)))
    ind.set(qn("w:hanging"), str(round(tokens["list_hanging"] * 1440)))
    ppr.append(ind)
    lvl.append(ppr)
    abstract.append(lvl)
    root.append(abstract)

    num = OxmlElement("w:num")
    num.set(qn("w:numId"), str(num_id))
    ref = OxmlElement("w:abstractNumId")
    ref.set(qn("w:val"), str(abstract_id))
    num.append(ref)
    root.append(num)
    return num_id


def add_list_paragraph(
    doc: Document,
    text: str,
    num_id: int,
    tokens: dict[str, float],
) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(tokens["list_after"])
    p.paragraph_format.line_spacing = tokens["list_line"]
    ppr = p._p.get_or_add_pPr()
    num_pr = OxmlElement("w:numPr")
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), "0")
    num = OxmlElement("w:numId")
    num.set(qn("w:val"), str(num_id))
    num_pr.append(ilvl)
    num_pr.append(num)
    ppr.append(num_pr)
    base.add_inline_runs(p, text)


def add_body_paragraph(doc: Document, text: str, tokens: dict[str, float]) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(tokens["body_after"])
    p.paragraph_format.line_spacing = tokens["body_line"]
    base.add_inline_runs(p, text)


def add_report_image(doc: Document, alt: str, rel_path: str) -> None:
    """Add an image at a readable size without overflowing portrait pages."""
    img_path = (ROOT / "report" / rel_path).resolve()
    if not img_path.exists():
        p = doc.add_paragraph()
        base.add_inline_runs(p, f"[이미지 누락: {alt} - {rel_path}]")
        return

    with PILImage.open(img_path) as image:
        width_px, height_px = image.size
    portrait = height_px / max(width_px, 1) > 1.35
    width = Inches(2.35 if portrait else 4.5)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    shape = p.add_run().add_picture(str(img_path), width=width)
    shape._inline.docPr.set("descr", alt)
    shape._inline.docPr.set("title", alt)

    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cap.paragraph_format.space_after = Pt(8)
    base.set_run_font(cap.add_run(alt), size=8.5, color=MUTED)


def build(config: ReportConfig) -> Path:
    markdown = config.source.read_text(encoding="utf-8")
    doc = Document()
    set_document_language(doc)
    tokens = configure_styles(doc, config)
    add_cover(doc, config)
    base.LIGHT_FILL = config.header_fill

    lines = base.parse_body_lines(markdown)
    idx = 0
    while idx < len(lines):
        line = lines[idx]
        if not line.strip():
            idx += 1
            continue
        if line.startswith("```"):
            idx += 1
            code = []
            while idx < len(lines) and not lines[idx].startswith("```"):
                code.append(lines[idx])
                idx += 1
            base.add_code_block(doc, code)
            idx += 1
            continue
        if line.startswith("|") and idx + 1 < len(lines) and lines[idx + 1].startswith("|"):
            rows = [base.split_table_row(line)]
            idx += 2
            while idx < len(lines) and lines[idx].startswith("|"):
                rows.append(base.split_table_row(lines[idx]))
                idx += 1
            base.add_table(doc, rows)
            continue
        image = re.match(r"!\[([^\]]*)\]\(([^)]+)\)", line.strip())
        if image:
            add_report_image(doc, image.group(1), image.group(2))
            idx += 1
            continue
        heading = re.match(r"^(#{2,4})\s+(.*)$", line)
        if heading:
            base.add_heading(doc, heading.group(2), len(heading.group(1)) - 1)
            idx += 1
            continue
        if re.match(r"^-\s+", line):
            num_id = add_numbering(doc, bullet=True, tokens=tokens)
            while idx < len(lines):
                item = re.match(r"^-\s+(.*)$", lines[idx])
                if not item:
                    break
                add_list_paragraph(doc, item.group(1), num_id, tokens)
                idx += 1
            continue
        if re.match(r"^\d+\.\s+", line):
            num_id = add_numbering(doc, bullet=False, tokens=tokens)
            while idx < len(lines):
                item = re.match(r"^\d+\.\s+(.*)$", lines[idx])
                if not item:
                    break
                add_list_paragraph(doc, item.group(1), num_id, tokens)
                idx += 1
            continue
        if line.startswith(">"):
            p = doc.add_paragraph()
            p.paragraph_format.left_indent = Inches(0.25)
            p.paragraph_format.space_after = Pt(tokens["body_after"])
            base.paragraph_bottom_border(p, "D7DBE2", "4")
            base.add_inline_runs(p, line.lstrip("> ").strip(), color=MUTED)
            idx += 1
            continue
        add_body_paragraph(doc, line, tokens)
        idx += 1

    config.output.parent.mkdir(parents=True, exist_ok=True)
    doc.save(config.output)
    base.embed_nanum_fonts(config.output)
    return config.output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--kind", choices=sorted(CONFIGS), required=True)
    args = parser.parse_args()
    print(build(CONFIGS[args.kind]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
