#!/usr/bin/env node
/** Build editable A4-portrait evaluator-facing report decks. */

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = process.env.PROPERTY_SHOT_ROOT
  ? path.resolve(process.env.PROPERTY_SHOT_ROOT)
  : path.resolve(SCRIPT_DIR, "../..");
const PAGE = { width: 794, height: 1123 };
const MARGIN = 56;
const CONTENT_WIDTH = PAGE.width - MARGIN * 2;
const CONTENT_TOP = 140;
const CONTENT_BOTTOM = 1042;
const FONT = "NanumGothic";
const COLORS = {
  ink: "#173A3F",
  muted: "#607477",
  teal: "#2C7A7B",
  paleTeal: "#E8F4F1",
  gold: "#D7A23D",
  coral: "#F47661",
  cream: "#FFF9E7",
  line: "#D7E1DE",
  white: "#FFFFFF",
  code: "#F3F6F5",
};

const CONFIGS = [
  {
    source: path.join(ROOT, "report/game_introduction.md"),
    output: path.join(ROOT, "report/dist/property_shot_game_guide.pptx"),
    kicker: "GAME GUIDE",
    title: "속성 한방(Property Shot)",
    subtitle: "게임 소개 및 설명",
    running: "Property Shot · Game Guide",
    tagline: "속성을 옮기고, 실패까지 다음 해법으로 바꾸는 물리 퍼즐",
    coverImage: path.join(ROOT, "screenshots/commercial-vertical-slice/390x844-current-play-audit.png"),
  },
  {
    source: path.join(ROOT, "report/ai_technical_report.md"),
    output: path.join(ROOT, "report/dist/property_shot_ai_technical_report.pptx"),
    kicker: "AI TECHNICAL REPORT",
    title: "속성 한방(Property Shot)",
    subtitle: "AI 활용 기술 문서",
    running: "Property Shot · AI Technical Report",
    tagline: "프롬프트를 제작 계약으로 바꾸고, 독립 감사로 검증한 AI 협업",
    coverImage: path.join(ROOT, "test/goldens/difficulty_easy_first_arrival_390x844.png"),
  },
  {
    source: path.join(ROOT, "report/portfolio.md"),
    output: path.join(ROOT, "report/dist/property_shot_portfolio.pptx"),
    kicker: "GAME · AI · PRODUCT CASE STUDY",
    title: "속성 한방(Property Shot)",
    subtitle: "프로젝트 포트폴리오",
    running: "Property Shot · Portfolio",
    tagline: "게임 디렉팅, AI 오케스트레이션, 검증 가능한 제품 제작",
    coverImage: path.join(ROOT, "screenshots/commercial-vertical-slice/stage4-property-ready.png"),
  },
];

function cleanInline(value) {
  return value
    .replace(/`([^`]+)`/g, "$1")
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1 ($2)")
    .replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1")
    .replace(/^>\s?/, "")
    .trim();
}

function extractUrls(text) {
  return [...new Set(text.match(/https?:\/\/[^\s)\]]+/g) ?? [])];
}

function parseTableRow(line) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((value) => cleanInline(value));
}

function isTableDivider(line) {
  return /^\|?\s*:?-{3,}/.test(line.trim());
}

function parseMarkdown(markdown, sourcePath) {
  const lines = markdown.split(/\r?\n/);
  const blocks = [];
  let title = "";
  let index = 0;
  while (index < lines.length) {
    const raw = lines[index];
    const line = raw.trim();
    if (!line) {
      index += 1;
      continue;
    }
    if (line.startsWith("# ")) {
      title = cleanInline(line.slice(2));
      index += 1;
      continue;
    }
    if (line.startsWith("## ")) {
      blocks.push({ type: "section", text: cleanInline(line.slice(3)), raw: line });
      index += 1;
      continue;
    }
    if (line.startsWith("### ")) {
      blocks.push({ type: "subheading", text: cleanInline(line.slice(4)), raw: line });
      index += 1;
      continue;
    }
    const imageMatch = line.match(/^!\[([^\]]*)\]\(([^)]+)\)$/);
    if (imageMatch) {
      blocks.push({
        type: "image",
        alt: imageMatch[1],
        source: path.resolve(path.dirname(sourcePath), imageMatch[2]),
        raw: line,
      });
      index += 1;
      continue;
    }
    if (line.startsWith("```")) {
      const code = [];
      index += 1;
      while (index < lines.length && !lines[index].trim().startsWith("```")) {
        code.push(lines[index]);
        index += 1;
      }
      index += 1;
      blocks.push({ type: "code", text: code.join("\n"), raw: code.join("\n") });
      continue;
    }
    if (line.startsWith("|") && index + 1 < lines.length && isTableDivider(lines[index + 1])) {
      const rows = [parseTableRow(lines[index])];
      index += 2;
      while (index < lines.length && lines[index].trim().startsWith("|")) {
        rows.push(parseTableRow(lines[index]));
        index += 1;
      }
      blocks.push({ type: "table", rows, raw: rows.flat().join(" ") });
      continue;
    }
    if (/^[-*]\s+/.test(line) || /^\d+\.\s+/.test(line)) {
      const items = [];
      while (index < lines.length) {
        const itemLine = lines[index].trim();
        const itemMatch = itemLine.match(/^(?:[-*]|\d+\.)\s+(.*)$/);
        if (!itemMatch) break;
        items.push(cleanInline(itemMatch[1]));
        index += 1;
      }
      blocks.push({ type: "bullets", items, raw: items.join(" ") });
      continue;
    }
    if (line === "---") {
      index += 1;
      continue;
    }
    const paragraph = [line];
    index += 1;
    while (index < lines.length) {
      const next = lines[index].trim();
      if (!next) break;
      if (/^(#{1,3}\s|!\[|```|\||[-*]\s+|\d+\.\s+|---$)/.test(next)) break;
      paragraph.push(next);
      index += 1;
    }
    const rawText = paragraph.join(" ");
    blocks.push({ type: "paragraph", text: cleanInline(rawText), raw: rawText });
  }
  return { title, blocks };
}

function wrapEstimate(text, charsPerLine = 44) {
  const weighted = [...text].reduce((sum, char) => sum + (char.charCodeAt(0) > 127 ? 1 : 0.58), 0);
  return Math.max(1, Math.ceil(weighted / charsPerLine));
}

function textHeight(text, fontSize = 16, charsPerLine = 44) {
  return wrapEstimate(text, charsPerLine) * (fontSize * 1.52) + 12;
}

function splitParagraph(text, maxChars = 480) {
  if (text.length <= maxChars) return [text];
  const sentences = text.split(/(?<=[.!?다요함됨음])\s+/);
  const result = [];
  let current = "";
  for (const sentence of sentences) {
    if (current && current.length + sentence.length + 1 > maxChars) {
      result.push(current);
      current = sentence;
    } else {
      current = current ? `${current} ${sentence}` : sentence;
    }
  }
  if (current) result.push(current);
  return result;
}

function addTextBox(slide, name, text, frame, style = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name,
    position: frame,
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: FONT,
    fontSize: style.fontSize ?? 16,
    bold: style.bold ?? false,
    color: style.color ?? COLORS.ink,
    alignment: style.alignment ?? "left",
    verticalAlignment: style.verticalAlignment ?? "top",
    lineSpacing: style.lineSpacing ?? 1.2,
    autoFit: "shrinkText",
    insets: style.insets ?? { top: 0, right: 0, bottom: 0, left: 0 },
  };
  return shape;
}

function addChrome(slide, config, title, pageNumber, continued = false) {
  slide.background.fill = COLORS.white;
  addTextBox(slide, "running-label", config.running, { left: MARGIN, top: 32, width: 430, height: 22 }, {
    fontSize: 12,
    bold: true,
    color: COLORS.teal,
  });
  addTextBox(slide, "page-number", String(pageNumber), { left: PAGE.width - MARGIN - 40, top: 32, width: 40, height: 22 }, {
    fontSize: 12,
    color: COLORS.muted,
    alignment: "right",
  });
  slide.shapes.add({
    geometry: "rect",
    name: "header-rule",
    position: { left: MARGIN, top: 66, width: CONTENT_WIDTH, height: 3 },
    fill: COLORS.gold,
    line: { style: "solid", fill: "none", width: 0 },
  });
  addTextBox(slide, "slide-title", continued ? `${title} · 계속` : title, { left: MARGIN, top: 84, width: CONTENT_WIDTH, height: 48 }, {
    fontSize: 35,
    bold: true,
    color: COLORS.ink,
  });
}

async function addCover(presentation, config, pageNumber) {
  const slide = presentation.slides.add();
  slide.background.fill = COLORS.cream;
  slide.shapes.add({
    geometry: "rect",
    name: "cover-accent",
    position: { left: 0, top: 0, width: 18, height: PAGE.height },
    fill: COLORS.coral,
    line: { style: "solid", fill: "none", width: 0 },
  });
  addTextBox(slide, "cover-kicker", config.kicker, { left: 78, top: 160, width: 590, height: 34 }, {
    fontSize: 18,
    bold: true,
    color: COLORS.gold,
  });
  addTextBox(slide, "cover-title", config.title, { left: 78, top: 245, width: 640, height: 170 }, {
    fontSize: 50,
    bold: true,
    color: COLORS.ink,
    lineSpacing: 1.05,
  });
  addTextBox(slide, "cover-subtitle", config.subtitle, { left: 78, top: 430, width: 620, height: 62 }, {
    fontSize: 28,
    bold: true,
    color: COLORS.teal,
  });
  slide.shapes.add({
    geometry: "rect",
    name: "cover-rule",
    position: { left: 78, top: 532, width: 180, height: 5 },
    fill: COLORS.gold,
    line: { style: "solid", fill: "none", width: 0 },
  });
  addTextBox(slide, "cover-description", config.tagline, { left: 78, top: 570, width: 340, height: 160 }, {
    fontSize: 22,
    color: COLORS.muted,
    lineSpacing: 1.25,
  });
  const coverBytes = await fs.readFile(config.coverImage);
  slide.images.add({
    blob: coverBytes,
    contentType: "image/png",
    alt: "속성 한방 실제 플레이 화면",
    fit: "contain",
    geometry: "roundRect",
    borderRadius: "rounded-xl",
    position: { left: 470, top: 560, width: 230, height: 330 },
  });
  addTextBox(slide, "cover-meta", "NAN 2026 Game × AI 해커톤 사전 과제\n2026-08-10", { left: 78, top: 920, width: 610, height: 76 }, {
    fontSize: 17,
    color: COLORS.ink,
    lineSpacing: 1.3,
  });
  addTextBox(slide, "cover-page", String(pageNumber), { left: PAGE.width - 90, top: 1046, width: 34, height: 20 }, {
    fontSize: 12,
    color: COLORS.muted,
    alignment: "right",
  });
  slide.speakerNotes.textFrame.setText("[Sources]\n- Project report source and local repository assets\n- https://nan2026.nhn.com/");
  return slide;
}

async function addImage(slide, block, y) {
  const bytes = await fs.readFile(block.source);
  const ext = path.extname(block.source).toLowerCase();
  const contentType = ext === ".jpg" || ext === ".jpeg" ? "image/jpeg" : "image/png";
  const height = 330;
  slide.images.add({
    blob: bytes,
    contentType,
    alt: block.alt,
    fit: "contain",
    geometry: "roundRect",
    borderRadius: "rounded-xl",
    position: { left: MARGIN, top: y, width: CONTENT_WIDTH, height },
  });
  addTextBox(slide, `image-caption-${y}`, block.alt, { left: MARGIN + 14, top: y + height + 6, width: CONTENT_WIDTH - 28, height: 44 }, {
    fontSize: 14,
    color: COLORS.muted,
    alignment: "center",
  });
  return height + 54;
}

function addParagraph(slide, text, y, kind = "paragraph") {
  const fontSize = kind === "subheading" ? 24 : kind === "code" ? 15 : 16;
  const height = kind === "subheading" ? 42 : textHeight(text, fontSize, kind === "code" ? 58 : 44);
  if (kind === "subheading") {
    addTextBox(slide, `subheading-${y}`, text, { left: MARGIN, top: y, width: CONTENT_WIDTH, height }, {
      fontSize,
      bold: true,
      color: COLORS.teal,
    });
  } else if (kind === "code") {
    slide.shapes.add({
      geometry: "roundRect",
      name: `code-bg-${y}`,
      position: { left: MARGIN, top: y, width: CONTENT_WIDTH, height: height + 20 },
      fill: COLORS.code,
      line: { style: "solid", fill: COLORS.line, width: 1 },
      borderRadius: "rounded-lg",
    });
    addTextBox(slide, `code-${y}`, text, { left: MARGIN + 16, top: y + 10, width: CONTENT_WIDTH - 32, height }, {
      fontSize,
      color: COLORS.ink,
      lineSpacing: 1.15,
    });
    return height + 28;
  } else {
    addTextBox(slide, `paragraph-${y}`, text, { left: MARGIN, top: y, width: CONTENT_WIDTH, height }, {
      fontSize,
      color: COLORS.ink,
      lineSpacing: 1.22,
    });
  }
  return height + 12;
}

function addBullets(slide, items, y) {
  const paragraphs = items.map((item) => ({
    bulletCharacter: "•",
    marginLeft: 20,
    indent: -12,
    spaceAfter: 8,
    runs: [{ run: item, textStyle: { typeface: FONT, fontSize: "16px", color: COLORS.ink } }],
  }));
  const height = items.reduce((sum, item) => sum + textHeight(item, 16, 41), 0) + 8;
  const shape = slide.shapes.add({
    geometry: "textbox",
    name: `bullets-${y}`,
    position: { left: MARGIN, top: y, width: CONTENT_WIDTH, height },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text.set(paragraphs);
  shape.text.style = { typeface: FONT, fontSize: 16, color: COLORS.ink, lineSpacing: 1.18, autoFit: "shrinkText" };
  return height + 10;
}

function tableMetrics(rows) {
  const columns = Math.max(...rows.map((row) => row.length));
  const normalized = rows.map((row) => Array.from({ length: columns }, (_, index) => row[index] ?? ""));
  const columnWidth = CONTENT_WIDTH / columns;
  const fontSize = columns >= 4 ? 13 : 14;
  const charsPerLine = Math.max(10, Math.floor((columnWidth - 18) / (fontSize * 0.56)));
  const rowHeights = normalized.map((row, rowIndex) => {
    const lines = Math.max(...row.map((cell) => wrapEstimate(cell, charsPerLine)));
    return Math.max(rowIndex === 0 ? 48 : 42, lines * (fontSize * 1.35) + 18);
  });
  return { columns, normalized, columnWidth, fontSize, rowHeights, height: rowHeights.reduce((sum, value) => sum + value, 0) };
}

function addTable(slide, rows, y) {
  // Tables are composed from editable rectangles and text boxes. This gives
  // every wrapped row its measured height; PowerPoint/LibreOffice otherwise
  // auto-expands long Korean paths and URLs beyond the table's nominal box.
  const metrics = tableMetrics(rows);
  let rowTop = y;
  for (let row = 0; row < metrics.normalized.length; row += 1) {
    const rowHeight = metrics.rowHeights[row];
    for (let column = 0; column < metrics.columns; column += 1) {
      const left = MARGIN + column * metrics.columnWidth;
      slide.shapes.add({
        geometry: "rect",
        name: `table-cell-${y}-${row}-${column}`,
        position: { left, top: rowTop, width: metrics.columnWidth, height: rowHeight },
        fill: row === 0 ? COLORS.paleTeal : row % 2 === 0 ? "#FAFCFB" : COLORS.white,
        line: { style: "solid", fill: COLORS.line, width: 1 },
      });
      addTextBox(
        slide,
        `table-text-${y}-${row}-${column}`,
        metrics.normalized[row][column],
        { left: left + 9, top: rowTop + 7, width: metrics.columnWidth - 18, height: rowHeight - 14 },
        {
          fontSize: metrics.fontSize,
          bold: row === 0,
          color: COLORS.ink,
          lineSpacing: 1.08,
          insets: { top: 0, right: 0, bottom: 0, left: 0 },
        },
      );
    }
    rowTop += rowHeight;
  }
  return metrics.height + 16;
}

function blockHeight(block) {
  if (block.type === "subheading") return 54;
  if (block.type === "paragraph") return textHeight(block.text, 16, 44) + 12;
  if (block.type === "code") return textHeight(block.text, 15, 58) + 28;
  if (block.type === "bullets") return block.items.reduce((sum, item) => sum + textHeight(item, 16, 41), 0) + 18;
  if (block.type === "image") return 384;
  if (block.type === "table") return tableMetrics(block.rows).height + 16;
  return 0;
}

function normalizeBlocks(blocks) {
  const normalized = [];
  for (const block of blocks) {
    if (block.type === "paragraph") {
      for (const text of splitParagraph(block.text)) normalized.push({ ...block, text, raw: text });
    } else if (block.type === "bullets" && block.items.length > 5) {
      for (let index = 0; index < block.items.length; index += 5) {
        const items = block.items.slice(index, index + 5);
        normalized.push({ ...block, items, raw: items.join(" ") });
      }
    } else if (block.type === "table") {
      const header = block.rows[0];
      let rows = [header];
      for (const row of block.rows.slice(1)) {
        const candidate = [...rows, row];
        if (rows.length > 1 && tableMetrics(candidate).height > 680) {
          normalized.push({ ...block, rows, raw: rows.flat().join(" ") });
          rows = [header, row];
        } else {
          rows = candidate;
        }
      }
      if (rows.length > 1) normalized.push({ ...block, rows, raw: rows.flat().join(" ") });
    } else {
      normalized.push(block);
    }
  }
  return normalized;
}

async function buildDeck(config) {
  const markdown = await fs.readFile(config.source, "utf8");
  const parsed = parseMarkdown(markdown, config.source);
  const presentation = Presentation.create({ slideSize: PAGE });
  let pageNumber = 1;
  await addCover(presentation, config, pageNumber);
  pageNumber += 1;

  let currentSection = "문서 개요";
  let sectionBlocks = [];

  async function flushSection() {
    if (!sectionBlocks.length) return;
    const blocks = normalizeBlocks(sectionBlocks);
    let slide = null;
    let y = CONTENT_TOP;
    let continued = false;
    let slideSources = new Set([path.relative(ROOT, config.source)]);

    function startSlide() {
      slide = presentation.slides.add();
      addChrome(slide, config, currentSection, pageNumber, continued);
      pageNumber += 1;
      y = CONTENT_TOP;
      slideSources = new Set([path.relative(ROOT, config.source)]);
      continued = true;
    }

    function finishSlide() {
      if (!slide) return;
      slide.speakerNotes.textFrame.setText(`[Sources]\n${[...slideSources].map((source) => `- ${source}`).join("\n")}`);
    }

    startSlide();
    for (const block of blocks) {
      const needed = blockHeight(block);
      if (y + needed > CONTENT_BOTTOM && y > CONTENT_TOP + 30) {
        finishSlide();
        startSlide();
      }
      for (const url of extractUrls(block.raw ?? "")) slideSources.add(url);
      if (block.type === "image") {
        slideSources.add(path.relative(ROOT, block.source));
        y += await addImage(slide, block, y);
      } else if (block.type === "subheading") {
        y += addParagraph(slide, block.text, y, "subheading");
      } else if (block.type === "paragraph") {
        y += addParagraph(slide, block.text, y, "paragraph");
      } else if (block.type === "code") {
        y += addParagraph(slide, block.text, y, "code");
      } else if (block.type === "bullets") {
        y += addBullets(slide, block.items, y);
      } else if (block.type === "table") {
        y += addTable(slide, block.rows, y);
      }
    }
    finishSlide();
  }

  for (const block of parsed.blocks) {
    if (block.type === "section") {
      await flushSection();
      currentSection = block.text;
      sectionBlocks = [];
    } else {
      sectionBlocks.push(block);
    }
  }
  await flushSection();

  await fs.mkdir(path.dirname(config.output), { recursive: true });
  const pptx = await PresentationFile.exportPptx(presentation);
  await pptx.save(config.output);
  const slideCount = presentation.slides.items.length;
  return { output: config.output, slideCount, sourceTitle: parsed.title };
}

async function main() {
  const results = [];
  for (const config of CONFIGS) results.push(await buildDeck(config));
  console.log(JSON.stringify(results, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
