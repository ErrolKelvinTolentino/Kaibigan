from __future__ import annotations

from pathlib import Path
from textwrap import wrap

from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "output"
TMP_DIR = ROOT / "tmp" / "docs" / "kaibigan_documentation"
DOCX_PATH = OUT_DIR / "Kaibigan_Project_Documentation_ERD_Updated.docx"
FLOW_PATH = TMP_DIR / "kaibigan_system_flowchart.png"
JOURNAL_FLOW_PATH = TMP_DIR / "kaibigan_journal_ai_crud_flowchart.png"
PERSISTENCE_FLOW_PATH = TMP_DIR / "kaibigan_other_crud_persistence_flowchart.png"
ERD_PATH = TMP_DIR / "kaibigan_erd.png"
LOGO_PATH = ROOT / "kaibigan_flutter" / "assets" / "Kaibigan Logo.png"

OUT_DIR.mkdir(parents=True, exist_ok=True)
TMP_DIR.mkdir(parents=True, exist_ok=True)


INK = "242724"
MUTED = "6B716C"
YELLOW = "FFD21F"
PALE_YELLOW = "FFF6CC"
CREAM = "FFF9ED"
GREEN = "3C6E5A"
PALE_GREEN = "E9F3EE"
BLUE = "426A83"
PALE_BLUE = "EAF2F7"
LINE = "D8D9D2"
WHITE = "FFFFFF"


def rgb(hex_value: str) -> RGBColor:
    return RGBColor.from_string(hex_value)


def font_path(bold: bool = False) -> str:
    preferred = Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf")
    if preferred.exists():
        return str(preferred)
    return "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"


def pil_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(font_path(bold), size=size)


def css(value: str) -> str:
    return value if value.startswith("#") else f"#{value}"


def set_cell_like_fill(paragraph, fill: str, border: str = LINE) -> None:
    p_pr = paragraph._p.get_or_add_pPr()
    shd = p_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        p_pr.append(shd)
    shd.set(qn("w:fill"), fill)
    p_bdr = p_pr.find(qn("w:pBdr"))
    if p_bdr is None:
        p_bdr = OxmlElement("w:pBdr")
        p_pr.append(p_bdr)
    for edge in ("top", "left", "bottom", "right"):
        element = p_bdr.find(qn(f"w:{edge}"))
        if element is None:
            element = OxmlElement(f"w:{edge}")
            p_bdr.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), "6")
        element.set(qn("w:space"), "8")
        element.set(qn("w:color"), border)


def set_run_font(run, size: float | None = None, bold: bool | None = None,
                 color: str | None = None, italic: bool | None = None,
                 name: str = "Arial") -> None:
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if italic is not None:
        run.italic = italic
    if color is not None:
        run.font.color.rgb = rgb(color)


def set_style_font(style, name: str, size: float, color: str, bold: bool = False) -> None:
    style.font.name = name
    style._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    style._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    style.font.size = Pt(size)
    style.font.color.rgb = rgb(color)
    style.font.bold = bold


def set_repeat_header_text(section, left: str, right: str) -> None:
    section.header.is_linked_to_previous = False
    header = section.header
    p = header.paragraphs[0]
    p.clear()
    p.paragraph_format.space_after = Pt(4)
    tabs = p.paragraph_format.tab_stops
    tabs.add_tab_stop(Inches(6.5), alignment=2)
    left_run = p.add_run(left.upper())
    set_run_font(left_run, 8.5, True, GREEN)
    p.add_run("\t")
    right_run = p.add_run(right)
    set_run_font(right_run, 8.5, False, MUTED)


def add_page_number(paragraph) -> None:
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("Page ")
    set_run_font(run, 8.5, False, MUTED)
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = " PAGE "
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char1, instr_text, fld_char2])


def set_footer(section) -> None:
    section.footer.is_linked_to_previous = False
    p = section.footer.paragraphs[0]
    p.clear()
    add_page_number(p)


def add_numbering_definition(doc: Document, ordered: bool) -> int:
    numbering = doc.part.numbering_part.element
    abstract_ids = [int(el.get(qn("w:abstractNumId"))) for el in numbering.findall(qn("w:abstractNum"))]
    num_ids = [int(el.get(qn("w:numId"))) for el in numbering.findall(qn("w:num"))]
    abstract_id = max(abstract_ids, default=0) + 1
    num_id = max(num_ids, default=0) + 1

    abstract = OxmlElement("w:abstractNum")
    abstract.set(qn("w:abstractNumId"), str(abstract_id))
    multi = OxmlElement("w:multiLevelType")
    multi.set(qn("w:val"), "multilevel")
    abstract.append(multi)
    for level in range(3):
        lvl = OxmlElement("w:lvl")
        lvl.set(qn("w:ilvl"), str(level))
        start = OxmlElement("w:start")
        start.set(qn("w:val"), "1")
        lvl.append(start)
        num_fmt = OxmlElement("w:numFmt")
        num_fmt.set(qn("w:val"), "decimal" if ordered else "bullet")
        lvl.append(num_fmt)
        lvl_text = OxmlElement("w:lvlText")
        if ordered:
            lvl_text.set(qn("w:val"), f"%{level + 1}.")
        else:
            lvl_text.set(qn("w:val"), "•")
        lvl.append(lvl_text)
        suff = OxmlElement("w:suff")
        suff.set(qn("w:val"), "tab")
        lvl.append(suff)
        p_pr = OxmlElement("w:pPr")
        tabs = OxmlElement("w:tabs")
        tab = OxmlElement("w:tab")
        tab.set(qn("w:val"), "num")
        left = 540 + level * 360
        tab.set(qn("w:pos"), str(left))
        tabs.append(tab)
        p_pr.append(tabs)
        ind = OxmlElement("w:ind")
        ind.set(qn("w:left"), str(left))
        ind.set(qn("w:hanging"), "270")
        p_pr.append(ind)
        lvl.append(p_pr)
        abstract.append(lvl)
    numbering.append(abstract)

    num = OxmlElement("w:num")
    num.set(qn("w:numId"), str(num_id))
    abstract_ref = OxmlElement("w:abstractNumId")
    abstract_ref.set(qn("w:val"), str(abstract_id))
    num.append(abstract_ref)
    numbering.append(num)
    return num_id


def set_list_number(paragraph, num_id: int, level: int = 0) -> None:
    p_pr = paragraph._p.get_or_add_pPr()
    num_pr = p_pr.find(qn("w:numPr"))
    if num_pr is None:
        num_pr = OxmlElement("w:numPr")
        p_pr.append(num_pr)
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), str(level))
    num_id_el = OxmlElement("w:numId")
    num_id_el.set(qn("w:val"), str(num_id))
    num_pr.extend([ilvl, num_id_el])


def add_list_item(doc: Document, text: str, num_id: int, level: int = 0,
                  bold_lead: str | None = None) -> None:
    p = doc.add_paragraph(style="List Body")
    set_list_number(p, num_id, level)
    if bold_lead and text.startswith(bold_lead):
        lead = p.add_run(bold_lead)
        set_run_font(lead, 10.5, True, INK)
        rest = p.add_run(text[len(bold_lead):])
        set_run_font(rest, 10.5, False, INK)
    else:
        run = p.add_run(text)
        set_run_font(run, 10.5, False, INK)


def add_body(doc: Document, text: str, first_indent: bool = False) -> None:
    p = doc.add_paragraph(style="Normal")
    if first_indent:
        p.paragraph_format.first_line_indent = Inches(0.32)
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.add_run(text)


def add_label(doc: Document, text: str) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(5)
    p.paragraph_format.space_after = Pt(3)
    run = p.add_run(text)
    set_run_font(run, 11.5, True, GREEN)


def add_note(doc: Document, label: str, text: str) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.16)
    p.paragraph_format.right_indent = Inches(0.16)
    p.paragraph_format.space_before = Pt(7)
    p.paragraph_format.space_after = Pt(9)
    set_cell_like_fill(p, PALE_YELLOW, YELLOW)
    r = p.add_run(f"{label}: ")
    set_run_font(r, 9.5, True, INK)
    r = p.add_run(text)
    set_run_font(r, 9.5, False, INK)


def draw_centered_text(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str,
                       font: ImageFont.FreeTypeFont, fill: str = "#242724",
                       line_gap: int = 8) -> None:
    x1, y1, x2, y2 = box
    max_width = x2 - x1 - 28
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if draw.textbbox((0, 0), candidate, font=font)[2] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    heights = [draw.textbbox((0, 0), line, font=font)[3] for line in lines]
    total_h = sum(heights) + line_gap * max(0, len(lines) - 1)
    y = y1 + ((y2 - y1) - total_h) / 2
    for line, h in zip(lines, heights):
        width = draw.textbbox((0, 0), line, font=font)[2]
        draw.text((x1 + ((x2 - x1) - width) / 2, y), line, font=font, fill=fill)
        y += h + line_gap


def arrow(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int],
          color: str = "#6B716C", width: int = 5) -> None:
    draw.line([start, end], fill=color, width=width)
    import math
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    length = 16
    for delta in (2.55, -2.55):
        point = (end[0] + length * math.cos(angle + delta), end[1] + length * math.sin(angle + delta))
        draw.line([end, point], fill=color, width=width)


def route_arrow(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]],
                color: str = "#6B716C", width: int = 5) -> None:
    draw.line(points, fill=color, width=width, joint="curve")
    arrow(draw, points[-2], points[-1], color=color, width=width)


def flow_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str,
             fill: str = "#FFFFFF", outline: str = "#3C6E5A", bold: bool = False,
             radius: int = 22) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=css(fill), outline=css(outline), width=5)
    draw_centered_text(draw, box, text, pil_font(31 if bold else 28, bold=bold))


def process_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str,
                fill: str = "#FFFFFF", outline: str = "#426A83", bold: bool = False) -> None:
    draw.rectangle(box, fill=css(fill), outline=css(outline), width=5)
    draw_centered_text(draw, box, text, pil_font(23 if not bold else 25, bold=bold), line_gap=6)


def terminator(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str) -> None:
    draw.ellipse(box, fill="#FFFFFF", outline="#242724", width=5)
    draw_centered_text(draw, box, text, pil_font(25, True), line_gap=4)


def decision(draw: ImageDraw.ImageDraw, center_x: int, top_y: int, width: int,
             height: int, text: str) -> tuple[tuple[int, int], tuple[int, int], tuple[int, int], tuple[int, int]]:
    top = (center_x, top_y)
    right = (center_x + width // 2, top_y + height // 2)
    bottom = (center_x, top_y + height)
    left = (center_x - width // 2, top_y + height // 2)
    draw.polygon([top, right, bottom, left], fill="#FFF6CC")
    draw.line([top, right, bottom, left, top], fill="#8A7213", width=5, joint="curve")
    draw_centered_text(
        draw,
        (left[0] + 28, top_y + 18, right[0] - 28, top_y + height - 18),
        text,
        pil_font(23, True),
        line_gap=4,
    )
    return top, right, bottom, left


def connector(draw: ImageDraw.ImageDraw, center: tuple[int, int], label: str,
              fill: str = "#E9F3EE") -> tuple[int, int]:
    x, y = center
    draw.ellipse((x - 42, y - 42, x + 42, y + 42), fill=fill, outline="#3C6E5A", width=5)
    draw_centered_text(draw, (x - 42, y - 42, x + 42, y + 42), label, pil_font(25, True))
    return center


def database_cylinder(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str,
                      fill: str = "#EAF2F7", outline: str = "#426A83") -> None:
    x1, y1, x2, y2 = box
    cap = 34
    draw.rectangle((x1, y1 + cap, x2, y2 - cap), fill=fill, outline=outline, width=5)
    draw.ellipse((x1, y1, x2, y1 + cap * 2), fill=fill, outline=outline, width=5)
    draw.ellipse((x1, y2 - cap * 2, x2, y2), fill=fill, outline=outline, width=5)
    draw.rectangle((x1 + 3, y1 + cap, x2 - 3, y2 - cap), fill=fill)
    draw.line((x1, y1 + cap, x1, y2 - cap), fill=outline, width=5)
    draw.line((x2, y1 + cap, x2, y2 - cap), fill=outline, width=5)
    draw.arc((x1, y2 - cap * 2, x2, y2), 0, 180, fill=outline, width=5)
    draw_centered_text(draw, (x1 + 12, y1 + 22, x2 - 12, y2 - 18), text, pil_font(21, True), line_gap=5)


def draw_flowchart(path: Path) -> None:
    image = Image.new("RGB", (1600, 2280), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((70, 38), "KAIBIGAN SYSTEM FLOWCHART", font=pil_font(43, True), fill="#242724")
    d.text(
        (70, 94),
        "Conventional Yes / No flow for authentication, feature use, persistence, and logout",
        font=pil_font(22),
        fill="#6B716C",
    )

    terminator(d, (560, 145, 1040, 235), "START")
    process_box(d, (500, 280, 1100, 385), "Initialize app, environment, Supabase, and notifications", PALE_BLUE, BLUE)
    auth_top, _, auth_bottom, auth_left = decision(d, 800, 430, 460, 160, "Authenticated session?")
    arrow(d, (800, 235), (800, 280))
    arrow(d, (800, 385), auth_top)

    process_box(d, (80, 450, 390, 555), "Open authentication page", "#FFFFFF", BLUE)
    process_box(d, (80, 635, 390, 740), "Enter email / password, register, use Google OAuth, or reset password", PALE_BLUE, BLUE)
    cred_top, cred_right, _, cred_left = decision(d, 235, 790, 370, 160, "Credentials valid?")
    route_arrow(d, [auth_left, (470, auth_left[1]), (390, auth_left[1])])
    d.text((462, auth_left[1] - 39), "No", font=pil_font(21, True), fill="#6B716C")
    arrow(d, (235, 555), (235, 635))
    arrow(d, (235, 740), cred_top)
    route_arrow(d, [cred_left, (30, cred_left[1]), (30, 502), (80, 502)])
    d.text((37, cred_left[1] - 40), "No", font=pil_font(21, True), fill="#6B716C")

    process_box(d, (540, 650, 1060, 755), "Display Home dashboard and adaptive support", YELLOW, INK, True)
    arrow(d, auth_bottom, (800, 650))
    d.text((825, 605), "Yes", font=pil_font(21, True), fill="#6B716C")
    route_arrow(d, [cred_right, (455, cred_right[1]), (455, 702), (540, 702)])
    d.text((430, cred_right[1] - 40), "Yes", font=pil_font(21, True), fill="#6B716C")

    feature_steps = [
        (830, "Open AI journal?", "Write or edit journal; optionally request AI reflection; save / sync; return Home", PALE_GREEN, GREEN),
        (1040, "Use tracking feature?", "Record mood, sleep, gratitude, or a future letter; save / sync; return Home", PALE_BLUE, BLUE),
        (1250, "Start a routine?", "Run the selected morning, midday, night, or custom routine; log completion; return Home", PALE_YELLOW, "#8A7213"),
        (1460, "Open support or learning?", "Complete grounding, breathing, affirmation, reflection, or learning activity; return Home", "#F3EDF8", "#705A7D"),
        (1670, "Open settings?", "Update profile, language, theme, appearance, notifications, or AI memory; return Home", PALE_GREEN, GREEN),
    ]
    arrow(d, (800, 755), (700, 830))
    for index, (top_y, question, process_text, fill, outline) in enumerate(feature_steps):
        next_top = feature_steps[index + 1][0] if index + 1 < len(feature_steps) else 1880
        _, right, bottom, _ = decision(d, 700, top_y, 400, 120, question)
        process_box(d, (990, top_y + 5, 1510, top_y + 115), process_text, fill, outline)
        arrow(d, right, (990, right[1]))
        d.text((910, right[1] - 38), "Yes", font=pil_font(20, True), fill="#6B716C")
        route_arrow(d, [(1250, top_y + 115), (1250, next_top - 28), (760, next_top - 28), (700, next_top)])
        arrow(d, bottom, (700, next_top))
        d.text((720, bottom[1] + 16), "No", font=pil_font(20, True), fill="#6B716C")

    _, _, logout_bottom, logout_left = decision(d, 700, 1880, 400, 120, "Log out of Kaibigan?")
    route_arrow(d, [logout_left, (455, logout_left[1]), (455, 702), (540, 702)])
    d.text((462, logout_left[1] - 39), "No", font=pil_font(20, True), fill="#6B716C")
    process_box(d, (530, 2045, 870, 2125), "Clear authentication session", PALE_BLUE, BLUE)
    arrow(d, logout_bottom, (700, 2045))
    d.text((725, 2010), "Yes", font=pil_font(20, True), fill="#6B716C")
    terminator(d, (540, 2160, 860, 2240), "END")
    arrow(d, (700, 2125), (700, 2160))

    image.save(path, quality=96)


def draw_navigation_flowchart(path: Path) -> None:
    image = Image.new("RGB", (1600, 2380), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((70, 38), "KAIBIGAN SYSTEM FLOWCHART — PART 1", font=pil_font(40, True), fill="#242724")
    d.text((70, 94), "Authentication, initial database reads, and sequential feature routing",
           font=pil_font(22), fill="#6B716C")

    terminator(d, (560, 145, 1040, 225), "START")
    process_box(d, (500, 265, 1100, 365), "Initialize app, environment, Supabase, and notifications", PALE_BLUE, BLUE)
    auth_top, _, auth_bottom, auth_left = decision(d, 800, 405, 460, 150, "Authenticated session?")
    arrow(d, (800, 225), (800, 265)); arrow(d, (800, 365), auth_top)

    process_box(d, (70, 425, 390, 525), "Open authentication page", "#FFFFFF", BLUE)
    process_box(d, (70, 590, 390, 710), "Enter credentials, register, use Google OAuth, or reset password", PALE_BLUE, BLUE)
    cred_top, cred_right, _, cred_left = decision(d, 230, 755, 350, 145, "Credentials valid?")
    route_arrow(d, [auth_left, (470, auth_left[1]), (390, auth_left[1])])
    d.text((430, auth_left[1] - 38), "No", font=pil_font(20, True), fill="#6B716C")
    arrow(d, (230, 525), (230, 590)); arrow(d, (230, 710), cred_top)
    route_arrow(d, [cred_left, (25, cred_left[1]), (25, 475), (70, 475)])
    d.text((35, cred_left[1] - 38), "No", font=pil_font(20, True), fill="#6B716C")

    process_box(d, (520, 620, 1080, 725), "Load profile and current user records", PALE_GREEN, GREEN, True)
    database_cylinder(d, (1160, 575, 1530, 770), "Supabase PostgreSQL\nSELECT with RLS\nprofiles + user tables")
    arrow(d, auth_bottom, (800, 620)); d.text((825, 570), "Yes", font=pil_font(20, True), fill="#6B716C")
    route_arrow(d, [cred_right, (460, cred_right[1]), (460, 672), (520, 672)])
    d.text((430, cred_right[1] - 38), "Yes", font=pil_font(20, True), fill="#6B716C")
    arrow(d, (1080, 672), (1160, 672))
    process_box(d, (520, 790, 1080, 885), "Display Home dashboard and adaptive support", YELLOW, INK, True)
    arrow(d, (800, 725), (800, 790))

    feature_steps = [
        (940, "Open journal?", "J"),
        (1130, "Open mood, gratitude, or future letters?", "D"),
        (1320, "Open a routine?", "R"),
        (1510, "Open settings or AI memory?", "S"),
        (1700, "Open local goals, learning, or reflection?", "L"),
    ]
    arrow(d, (800, 885), (700, 940))
    for index, (top_y, question, label) in enumerate(feature_steps):
        next_top = feature_steps[index + 1][0] if index + 1 < len(feature_steps) else 1900
        _, right, bottom, _ = decision(d, 700, top_y, 430, 115, question)
        connector(d, (1260, right[1]), label)
        arrow(d, right, (1218, right[1])); d.text((1060, right[1] - 36), "Yes", font=pil_font(19, True), fill="#6B716C")
        arrow(d, bottom, (700, next_top)); d.text((720, bottom[1] + 10), "No", font=pil_font(19, True), fill="#6B716C")

    _, logout_right, logout_bottom, _ = decision(d, 700, 1900, 430, 115, "Log out of Kaibigan?")
    route_arrow(d, [logout_right, (1480, logout_right[1]), (1480, 837), (1080, 837)])
    d.text((1060, logout_right[1] - 36), "No", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (520, 2060, 880, 2140), "Clear authentication session", PALE_BLUE, BLUE)
    arrow(d, logout_bottom, (700, 2060)); d.text((725, 2022), "Yes", font=pil_font(19, True), fill="#6B716C")
    terminator(d, (540, 2200, 860, 2280), "END"); arrow(d, (700, 2140), (700, 2200))
    d.text((70, 2320), "J, D, R, S, and L continue in Parts 2 and 3. H returns to Home.",
           font=pil_font(20, True), fill="#3C6E5A")
    image.save(path, quality=96)


def draw_journal_flowchart(path: Path) -> None:
    image = Image.new("RGB", (3000, 2000), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((70, 38), "KAIBIGAN SYSTEM FLOWCHART — PART 2", font=pil_font(40, True), fill="#242724")
    d.text((70, 92), "Journal CRUD, optional AI assistance, fallback handling, and exact cloud save points",
           font=pil_font(22), fill="#6B716C")

    connector(d, (120, 230), "J")
    process_box(d, (210, 175, 560, 285), "READ journal list", PALE_BLUE, BLUE, True)
    database_cylinder(d, (620, 145, 950, 315), "SELECT journal_entries\n(user_id + RLS)")
    create_top, create_right, create_bottom, _ = decision(d, 1130, 165, 330, 150, "Create new entry?")
    arrow(d, (162, 230), (210, 230)); arrow(d, (560, 230), (620, 230)); arrow(d, (950, 230), create_top)
    connector(d, (1410, create_right[1]), "C"); arrow(d, create_right, (1368, create_right[1]))
    d.text((1290, create_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    connector(d, (1130, 420), "E"); arrow(d, create_bottom, (1130, 378))
    d.text((1150, 330), "No", font=pil_font(19, True), fill="#6B716C")

    connector(d, (120, 560), "C")
    process_box(d, (210, 505, 550, 615), "Enter title and journal content", "#FFFFFF", BLUE)
    ai_top, ai_right, ai_bottom, _ = decision(d, 750, 485, 330, 150, "Request AI assistance?")
    arrow(d, (162, 560), (210, 560)); arrow(d, (550, 560), ai_top)
    process_box(d, (1040, 505, 1390, 615), "Apply input bounds and local crisis guardrail", PALE_YELLOW, "#8A7213")
    crisis_top, crisis_right, _, crisis_left = decision(d, 1215, 690, 350, 150, "Crisis language detected?")
    arrow(d, ai_right, (1040, ai_right[1])); d.text((930, ai_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    arrow(d, (1215, 615), crisis_top)
    process_box(d, (650, 900, 1030, 1010), "Display Philippine crisis and emergency resources", "#FBE8E8", "#9A3E3E")
    route_arrow(d, [crisis_left, (560, crisis_left[1]), (560, 955), (650, 955)])
    d.text((590, crisis_left[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (1430, 900, 1810, 1010), "Call authenticated Edge Function kaibigan-ai", PALE_BLUE, BLUE)
    route_arrow(d, [crisis_right, (1390, crisis_right[1]), (1390, 955), (1430, 955)])
    d.text((1370, crisis_right[1] - 38), "No", font=pil_font(19, True), fill="#6B716C")
    gem_top, gem_right, gem_bottom, _ = decision(d, 2020, 880, 330, 150, "Gemini succeeds?")
    arrow(d, (1810, 955), gem_top)
    process_box(d, (2280, 900, 2650, 1010), "Return structured AI reflection and safety level", PALE_GREEN, GREEN)
    arrow(d, gem_right, (2280, gem_right[1])); d.text((2190, gem_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (1840, 1115, 2200, 1225), "Try Groq fallback", "#F3EDF8", "#705A7D")
    arrow(d, gem_bottom, (2020, 1115)); d.text((2040, 1068), "No", font=pil_font(19, True), fill="#6B716C")
    groq_top, groq_right, groq_bottom, _ = decision(d, 2410, 1095, 330, 150, "Groq succeeds?")
    arrow(d, (2200, 1170), groq_top)
    process_box(d, (2640, 1115, 2960, 1225), "Return structured AI reflection", PALE_GREEN, GREEN)
    arrow(d, groq_right, (2640, groq_right[1])); d.text((2570, groq_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (2250, 1325, 2570, 1435), "Show AI unavailable; journal can still be saved", PALE_YELLOW, "#8A7213")
    arrow(d, groq_bottom, (2410, 1325)); d.text((2430, 1280), "No", font=pil_font(19, True), fill="#6B716C")

    save_top, save_right, save_bottom, save_left = decision(d, 1540, 1300, 330, 150, "Save journal entry?")
    route_arrow(d, [ai_bottom, (750, 1375), save_left]); d.text((770, 655), "No", font=pil_font(19, True), fill="#6B716C")
    route_arrow(d, [(1030, 955), (1080, 955), (1080, 1375), save_left])
    route_arrow(d, [(2650, 955), (2760, 955), (2760, 1475), (1540, 1475), save_bottom])
    route_arrow(d, [(2960, 1170), (2980, 1170), (2980, 1490), (1540, 1490), save_bottom])
    route_arrow(d, [(2570, 1380), (2600, 1380), (2600, 1490), (1540, 1490), save_bottom])
    process_box(d, (1840, 1320, 2200, 1430), "INSERT journal_entries with optional ai_response", PALE_GREEN, GREEN, True)
    arrow(d, save_right, (1840, save_right[1])); d.text((1740, save_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (1840, 1500, 2250, 1610), "After successful save, extract durable memory; INSERT if found", PALE_BLUE, BLUE)
    arrow(d, (2020, 1430), (2020, 1500))
    database_cylinder(d, (2300, 1490, 2600, 1620), "user_memories\nINSERT")
    arrow(d, (2250, 1555), (2300, 1555))
    database_cylinder(d, (2640, 1490, 2960, 1660), "journal_entries\nINSERT / UPDATE / DELETE")
    route_arrow(d, [(2200, 1375), (2480, 1375), (2480, 1490), (2640, 1575)])
    process_box(d, (1110, 1510, 1420, 1610), "Keep draft or discard; no cloud write", "#FFFFFF", MUTED)
    arrow(d, save_bottom, (1265, 1510)); d.text((1560, 1465), "No", font=pil_font(19, True), fill="#6B716C")

    connector(d, (120, 1770), "E")
    edit_top, edit_right, edit_bottom, _ = decision(d, 360, 1695, 300, 150, "Edit existing?")
    arrow(d, (162, 1770), edit_top)
    process_box(d, (590, 1715, 920, 1825), "UPDATE journal_entries; then extract memory", PALE_GREEN, GREEN)
    arrow(d, edit_right, (590, edit_right[1])); d.text((510, edit_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    delete_top, delete_right, delete_bottom, _ = decision(d, 1100, 1695, 300, 150, "Delete existing?")
    route_arrow(d, [edit_bottom, (360, 1905), (1100, 1905), delete_top]); d.text((380, 1855), "No", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (1330, 1715, 1630, 1825), "DELETE journal_entries after confirmation", "#FBE8E8", "#9A3E3E")
    arrow(d, delete_right, (1330, delete_right[1])); d.text((1250, delete_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    fav_top, fav_right, fav_bottom, _ = decision(d, 1810, 1695, 300, 150, "Toggle favorite?")
    route_arrow(d, [delete_bottom, (1100, 1905), (1810, 1905), fav_top]); d.text((1120, 1855), "No", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (2040, 1715, 2340, 1825), "UPDATE is_favorite", PALE_GREEN, GREEN)
    arrow(d, fav_right, (2040, fav_right[1])); d.text((1960, fav_right[1] - 38), "Yes", font=pil_font(19, True), fill="#6B716C")
    process_box(d, (2440, 1715, 2700, 1825), "View only; no write", "#FFFFFF", MUTED)
    route_arrow(d, [fav_bottom, (1810, 1905), (2570, 1905), (2570, 1825)]); d.text((1830, 1855), "No", font=pil_font(19, True), fill="#6B716C")
    connector(d, (2850, 1770), "H")
    for start in [(920, 1770), (1630, 1770), (2340, 1770), (2700, 1770), (2960, 1575), (2600, 1555), (1420, 1560)]:
        route_arrow(d, [start, (2780, start[1]), (2780, 1770), (2808, 1770)])
    image.save(path, quality=96)


def draw_persistence_flowchart(path: Path) -> None:
    image = Image.new("RGB", (3000, 2000), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((70, 38), "KAIBIGAN SYSTEM FLOWCHART — PART 3", font=pil_font(40, True), fill="#242724")
    d.text((70, 92), "Other CRUD operations, named data stores, and the moment each write occurs",
           font=pil_font(22), fill="#6B716C")
    lane_font = pil_font(24, True)

    d.text((70, 155), "DATA TRACKERS", font=lane_font, fill="#3C6E5A")
    connector(d, (120, 285), "D")
    process_box(d, (210, 230, 540, 340), "READ selected feature records", PALE_BLUE, BLUE)
    database_cylinder(d, (580, 205, 900, 365), "mood_logs\ngratitude_entries\nfuture_letters")
    c_top, c_right, c_bottom, _ = decision(d, 1100, 210, 300, 150, "Create record?")
    e_top, e_right, e_bottom, _ = decision(d, 1660, 210, 300, 150, "Edit record?")
    x_top, x_right, x_bottom, _ = decision(d, 2220, 210, 300, 150, "Delete record?")
    arrow(d, (162, 285), (210, 285)); arrow(d, (540, 285), (580, 285)); arrow(d, (900, 285), c_top)
    process_box(d, (980, 405, 1280, 505), "INSERT on Save", PALE_GREEN, GREEN); route_arrow(d, [c_right, (1250, c_right[1]), (1250, 405)])
    route_arrow(d, [c_bottom, (1100, 380), (1660, 380), e_top]); d.text((1120, 350), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (1540, 405, 1840, 505), "UPDATE on Save", PALE_GREEN, GREEN); route_arrow(d, [e_right, (1810, e_right[1]), (1810, 405)])
    route_arrow(d, [e_bottom, (1660, 380), (2220, 380), x_top]); d.text((1680, 350), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (2100, 405, 2400, 505), "DELETE after confirmation", "#FBE8E8", "#9A3E3E"); route_arrow(d, [x_right, (2370, x_right[1]), (2370, 405)])
    connector(d, (2800, 455), "H")
    for start in [(1280, 455), (1840, 455), (2400, 455), x_bottom]: route_arrow(d, [start, (2758, 455)])
    d.text((1270, 245), "Yes", font=pil_font(18, True), fill="#6B716C"); d.text((1830, 245), "Yes", font=pil_font(18, True), fill="#6B716C"); d.text((2390, 245), "Yes", font=pil_font(18, True), fill="#6B716C"); d.text((2240, 350), "No: view only", font=pil_font(18, True), fill="#6B716C")

    d.line((70, 590, 2930, 590), fill="#D8D9D2", width=4); d.text((70, 625), "ROUTINES", font=lane_font, fill="#3C6E5A")
    connector(d, (120, 760), "R")
    process_box(d, (210, 705, 600, 815), "READ routine config and active session from device", PALE_YELLOW, "#8A7213")
    done_top, done_right, done_bottom, _ = decision(d, 820, 685, 330, 150, "Routine completed?")
    arrow(d, (162, 760), (210, 760)); arrow(d, (600, 760), done_top)
    process_box(d, (1090, 705, 1470, 815), "INSERT routine_logs; clear active session", PALE_GREEN, GREEN)
    arrow(d, done_right, (1090, done_right[1])); d.text((1010, done_right[1]-38), "Yes", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (1540, 675, 1900, 845), "routine_logs\nSELECT / INSERT /\nUPDATE / DELETE"); arrow(d, (1470, 760), (1540, 760))
    process_box(d, (650, 900, 990, 1010), "Save resumable active session on device", PALE_YELLOW, "#8A7213")
    arrow(d, done_bottom, (820, 900)); d.text((840, 852), "No", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (2020, 675, 2430, 845), "SharedPreferences\nroutine configs +\nactive session"); route_arrow(d, [(990, 955), (2020, 955), (2020, 800)])
    connector(d, (2800, 760), "H"); route_arrow(d, [(1900, 760), (2758, 760)]); route_arrow(d, [(2430, 760), (2758, 760)])

    d.line((70, 1080, 2930, 1080), fill="#D8D9D2", width=4); d.text((70, 1115), "SETTINGS AND AI MEMORY", font=lane_font, fill="#3C6E5A")
    connector(d, (120, 1260), "S")
    p_top, p_right, p_bottom, _ = decision(d, 410, 1185, 320, 150, "Profile changed?")
    arrow(d, (162, 1260), p_top)
    process_box(d, (650, 1205, 970, 1315), "UPSERT profiles on Save", PALE_GREEN, GREEN); arrow(d, p_right, (650, p_right[1])); d.text((575, p_right[1]-38), "Yes", font=pil_font(18, True), fill="#6B716C")
    local_top, local_right, local_bottom, _ = decision(d, 1180, 1185, 340, 150, "Local preference changed?")
    route_arrow(d, [p_bottom, (410, 1380), (1180, 1380), local_top]); d.text((430, 1342), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (1440, 1205, 1770, 1315), "Write preferences to device", PALE_YELLOW, "#8A7213"); arrow(d, local_right, (1440, local_right[1])); d.text((1360, local_right[1]-38), "Yes", font=pil_font(18, True), fill="#6B716C")
    mem_top, mem_right, mem_bottom, _ = decision(d, 1980, 1185, 340, 150, "Delete AI memory?")
    route_arrow(d, [local_bottom, (1180, 1380), (1980, 1380), mem_top]); d.text((1200, 1342), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (2240, 1205, 2540, 1315), "DELETE user_memories after confirmation", "#FBE8E8", "#9A3E3E"); arrow(d, mem_right, (2240, mem_right[1])); d.text((2160, mem_right[1]-38), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (2800, 1260), "H")
    for start in [(970, 1260), (1770, 1260), (2540, 1260), mem_bottom]: route_arrow(d, [start, (2758, 1260)])
    d.text((2000, 1342), "No", font=pil_font(18, True), fill="#6B716C")

    d.line((70, 1480, 2930, 1480), fill="#D8D9D2", width=4); d.text((70, 1515), "LOCAL GOALS, LEARNING, AND REFLECTION", font=lane_font, fill="#3C6E5A")
    connector(d, (120, 1665), "L")
    g_top, g_right, g_bottom, _ = decision(d, 430, 1590, 340, 150, "Daily goal changed?")
    arrow(d, (162, 1665), g_top)
    process_box(d, (690, 1610, 1070, 1720), "Create, toggle, or reset daily goals on device", PALE_YELLOW, "#8A7213"); arrow(d, g_right, (690, g_right[1])); d.text((610, g_right[1]-38), "Yes", font=pil_font(18, True), fill="#6B716C")
    lr_top, lr_right, lr_bottom, _ = decision(d, 1320, 1590, 380, 150, "Learning or reflection changed?")
    route_arrow(d, [g_bottom, (430, 1795), (1320, 1795), lr_top]); d.text((450, 1752), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (1600, 1610, 1990, 1720), "Save learning progress or weekly reflection on device", PALE_YELLOW, "#8A7213"); arrow(d, lr_right, (1600, lr_right[1])); d.text((1520, lr_right[1]-38), "Yes", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (2100, 1570, 2520, 1760), "SharedPreferences\ndaily goals + learning\n+ weekly reflections")
    route_arrow(d, [(1070, 1665), (2100, 1665)]); arrow(d, (1990, 1665), (2100, 1665))
    connector(d, (2800, 1665), "H"); arrow(d, (2520, 1665), (2758, 1665)); route_arrow(d, [lr_bottom, (1320, 1840), (2700, 1840), (2700, 1665), (2758, 1665)]); d.text((1340, 1752), "No", font=pil_font(18, True), fill="#6B716C")
    d.text((70, 1920), "Current runtime: daily_goals and routine_configs save to SharedPreferences; the similarly named Supabase schema tables are not written by the current providers.",
           font=pil_font(20, True), fill="#9A5D00")
    image.save(path, quality=96)


def draw_journal_flowchart_clean(path: Path) -> None:
    image = Image.new("RGB", (3000, 2000), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((70, 35), "KAIBIGAN SYSTEM FLOWCHART — PART 2", font=pil_font(40, True), fill="#242724")
    d.text((70, 90), "Journal CRUD, optional AI assistance, fallback handling, and exact cloud save points",
           font=pil_font(22), fill="#6B716C")

    # Read and select create versus existing-entry operations.
    connector(d, (110, 230), "J")
    process_box(d, (190, 175, 480, 285), "READ journal list", PALE_BLUE, BLUE, True)
    database_cylinder(d, (540, 145, 850, 315), "SELECT\njournal_entries\n(user_id + RLS)")
    create_top, create_right, create_bottom, _ = decision(d, 1070, 155, 330, 150, "Create new entry?")
    arrow(d, (152, 230), (190, 230)); arrow(d, (480, 230), (540, 230)); arrow(d, (850, 230), create_top)
    connector(d, (1350, create_right[1]), "C"); arrow(d, create_right, (1308, create_right[1]))
    d.text((1260, create_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (1070, 410), "E"); arrow(d, create_bottom, (1070, 368))
    d.text((1090, 325), "No", font=pil_font(18, True), fill="#6B716C")

    # New entry and optional AI route. Repeated G connectors continue to the single Save decision.
    connector(d, (110, 570), "C")
    process_box(d, (190, 515, 500, 625), "Enter title and journal content", "#FFFFFF", BLUE)
    ai_top, ai_right, ai_bottom, _ = decision(d, 700, 495, 330, 150, "Request AI assistance?")
    arrow(d, (152, 570), (190, 570)); arrow(d, (500, 570), ai_top)
    connector(d, (700, 770), "G"); arrow(d, ai_bottom, (700, 728))
    d.text((720, 685), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (970, 515, 1300, 625), "Apply input bounds and local crisis guardrail", PALE_YELLOW, "#8A7213")
    arrow(d, ai_right, (970, ai_right[1])); d.text((900, ai_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    crisis_top, crisis_right, crisis_bottom, _ = decision(d, 1480, 495, 350, 150, "Crisis language detected?")
    arrow(d, (1300, 570), crisis_top)
    process_box(d, (1320, 735, 1640, 845), "Display Philippine crisis and emergency resources", "#FBE8E8", "#9A3E3E")
    arrow(d, crisis_bottom, (1480, 735)); d.text((1500, 685), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (1750, 790), "G"); arrow(d, (1640, 790), (1708, 790))
    process_box(d, (1730, 515, 2070, 625), "Call authenticated Edge Function kaibigan-ai", PALE_BLUE, BLUE)
    arrow(d, crisis_right, (1730, crisis_right[1])); d.text((1660, crisis_right[1] - 36), "No", font=pil_font(18, True), fill="#6B716C")
    gem_top, gem_right, gem_bottom, _ = decision(d, 2250, 495, 320, 150, "Gemini succeeds?")
    arrow(d, (2070, 570), gem_top)
    process_box(d, (2480, 515, 2820, 625), "Return structured AI reflection and safety level", PALE_GREEN, GREEN)
    arrow(d, gem_right, (2480, gem_right[1])); d.text((2410, gem_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (2890, 570), "G"); arrow(d, (2820, 570), (2848, 570))
    process_box(d, (2080, 735, 2380, 845), "Try Groq fallback", "#F3EDF8", "#705A7D")
    arrow(d, gem_bottom, (2250, 735)); d.text((2270, 685), "No", font=pil_font(18, True), fill="#6B716C")
    groq_top, groq_right, groq_bottom, _ = decision(d, 2580, 715, 320, 150, "Groq succeeds?")
    arrow(d, (2380, 790), groq_top)
    process_box(d, (2750, 735, 2970, 845), "Return AI reflection", PALE_GREEN, GREEN)
    arrow(d, groq_right, (2750, groq_right[1])); d.text((2690, groq_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (2400, 930, 2760, 1040), "Show AI unavailable; journal can still be saved", PALE_YELLOW, "#8A7213")
    arrow(d, groq_bottom, (2580, 930)); d.text((2600, 885), "No", font=pil_font(18, True), fill="#6B716C")
    connector(d, (2870, 985), "G"); arrow(d, (2760, 985), (2828, 985))

    # One save gate receives all G connectors without crossing the AI route.
    connector(d, (110, 1210), "G")
    save_top, save_right, save_bottom, _ = decision(d, 360, 1135, 330, 150, "Save journal entry?")
    arrow(d, (152, 1210), save_top)
    process_box(d, (620, 1155, 970, 1265), "INSERT journal_entries with optional ai_response", PALE_GREEN, GREEN, True)
    arrow(d, save_right, (620, save_right[1])); d.text((540, save_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (1030, 1135, 1340, 1285), "Supabase\njournal_entries\nINSERT")
    arrow(d, (970, 1210), (1030, 1210))
    process_box(d, (1400, 1155, 1790, 1265), "After successful save, extract durable memory", PALE_BLUE, BLUE)
    arrow(d, (1340, 1210), (1400, 1210))
    database_cylinder(d, (1850, 1135, 2160, 1285), "user_memories\nINSERT if found")
    arrow(d, (1790, 1210), (1850, 1210)); connector(d, (2260, 1210), "H"); arrow(d, (2160, 1210), (2218, 1210))
    process_box(d, (200, 1370, 520, 1470), "Keep draft or discard; no cloud write", "#FFFFFF", MUTED)
    arrow(d, save_bottom, (360, 1370)); d.text((380, 1325), "No", font=pil_font(18, True), fill="#6B716C")
    connector(d, (620, 1420), "H"); arrow(d, (520, 1420), (578, 1420))

    # Existing-entry CRUD uses one Yes and one No exit per decision.
    connector(d, (110, 1740), "E")
    edit_top, edit_right, _, edit_left = decision(d, 340, 1665, 300, 150, "Edit existing?")
    arrow(d, (152, 1740), edit_left)
    process_box(d, (570, 1685, 900, 1795), "UPDATE journal_entries; then extract memory", PALE_GREEN, GREEN)
    arrow(d, edit_right, (570, edit_right[1])); d.text((500, edit_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (990, 1740), "H"); arrow(d, (900, 1740), (948, 1740))
    delete_top, delete_right, _, delete_left = decision(d, 1260, 1665, 300, 150, "Delete existing?")
    route_arrow(d, [(340, 1815), (340, 1900), (1080, 1900), (1080, 1740), delete_left])
    d.text((360, 1830), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (1490, 1685, 1790, 1795), "DELETE journal_entries after confirmation", "#FBE8E8", "#9A3E3E")
    arrow(d, delete_right, (1490, delete_right[1])); d.text((1420, delete_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (1880, 1740), "H"); arrow(d, (1790, 1740), (1838, 1740))
    fav_top, fav_right, _, fav_left = decision(d, 2150, 1665, 300, 150, "Toggle favorite?")
    route_arrow(d, [(1260, 1815), (1260, 1900), (1970, 1900), (1970, 1740), fav_left])
    d.text((1280, 1830), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (2380, 1685, 2660, 1795), "UPDATE is_favorite", PALE_GREEN, GREEN)
    arrow(d, fav_right, (2380, fav_right[1])); d.text((2310, fav_right[1] - 36), "Yes", font=pil_font(18, True), fill="#6B716C")
    connector(d, (2760, 1740), "H"); arrow(d, (2660, 1740), (2718, 1740))
    process_box(d, (2380, 1880, 2660, 1970), "View only; no write", "#FFFFFF", MUTED)
    route_arrow(d, [(2150, 1815), (2150, 1925), (2380, 1925)]); d.text((2170, 1830), "No", font=pil_font(18, True), fill="#6B716C")
    connector(d, (2760, 1925), "H"); arrow(d, (2660, 1925), (2718, 1925))
    image.save(path, quality=96)


def draw_persistence_flowchart_clean(path: Path) -> None:
    image = Image.new("RGB", (3000, 2000), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((70, 35), "KAIBIGAN SYSTEM FLOWCHART — PART 3", font=pil_font(40, True), fill="#242724")
    d.text((70, 90), "Other CRUD operations, named data stores, and the moment each write occurs",
           font=pil_font(22), fill="#6B716C")
    lane_font = pil_font(24, True)

    # Cloud CRUD for mood, gratitude, and future letters.
    d.text((70, 175), "DATA TRACKERS — CLOUD CRUD", font=lane_font, fill="#3C6E5A")
    connector(d, (110, 300), "D")
    process_box(d, (190, 245, 470, 355), "READ selected records", PALE_BLUE, BLUE)
    database_cylinder(d, (520, 220, 830, 380), "mood_logs\ngratitude_entries\nfuture_letters")
    c_top, c_right, c_bottom, _ = decision(d, 1040, 225, 300, 150, "Create record?")
    e_top, e_right, e_bottom, e_left = decision(d, 1640, 225, 300, 150, "Edit record?")
    x_top, x_right, x_bottom, x_left = decision(d, 2240, 225, 300, 150, "Delete record?")
    arrow(d, (152, 300), (190, 300)); arrow(d, (470, 300), (520, 300)); arrow(d, (830, 300), c_top)
    route_arrow(d, [c_right, (1490, c_right[1]), e_left]); d.text((1300, c_right[1] - 36), "No", font=pil_font(18, True), fill="#6B716C")
    route_arrow(d, [e_right, (2090, e_right[1]), x_left]); d.text((1900, e_right[1] - 36), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (890, 430, 1190, 530), "INSERT when user taps Save", PALE_GREEN, GREEN); arrow(d, c_bottom, (1040, 430)); d.text((1060, 385), "Yes", font=pil_font(18, True), fill="#6B716C"); connector(d, (1280, 480), "H"); arrow(d, (1190, 480), (1238, 480))
    process_box(d, (1490, 430, 1790, 530), "UPDATE when changes are saved", PALE_GREEN, GREEN); arrow(d, e_bottom, (1640, 430)); d.text((1660, 385), "Yes", font=pil_font(18, True), fill="#6B716C"); connector(d, (1880, 480), "H"); arrow(d, (1790, 480), (1838, 480))
    process_box(d, (2090, 430, 2390, 530), "DELETE after confirmation", "#FBE8E8", "#9A3E3E"); arrow(d, x_bottom, (2240, 430)); d.text((2260, 385), "Yes", font=pil_font(18, True), fill="#6B716C"); connector(d, (2480, 480), "H"); arrow(d, (2390, 480), (2438, 480))
    process_box(d, (2570, 245, 2820, 355), "View only; no write", "#FFFFFF", MUTED); arrow(d, x_right, (2570, x_right[1])); d.text((2500, x_right[1] - 36), "No", font=pil_font(18, True), fill="#6B716C"); connector(d, (2910, 300), "H"); arrow(d, (2820, 300), (2868, 300))

    # Routines combine local configuration/session state with cloud completion logs.
    d.line((70, 610, 2930, 610), fill="#D8D9D2", width=4); d.text((70, 650), "ROUTINES — LOCAL STATE + CLOUD LOG", font=lane_font, fill="#3C6E5A")
    connector(d, (110, 780), "R"); process_box(d, (190, 725, 570, 835), "READ routine config and active session from device", PALE_YELLOW, "#8A7213")
    done_top, done_right, done_bottom, _ = decision(d, 790, 705, 330, 150, "Routine completed?")
    arrow(d, (152, 780), (190, 780)); arrow(d, (570, 780), done_top)
    process_box(d, (1060, 725, 1430, 835), "INSERT routine_logs; clear active session", PALE_GREEN, GREEN); arrow(d, done_right, (1060, done_right[1])); d.text((990, done_right[1]-36), "Yes", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (1490, 695, 1840, 865), "routine_logs\nSELECT / INSERT /\nUPDATE / DELETE"); arrow(d, (1430, 780), (1490, 780)); connector(d, (1930, 780), "H"); arrow(d, (1840, 780), (1888, 780))
    process_box(d, (620, 920, 960, 1030), "Save resumable active session on device", PALE_YELLOW, "#8A7213"); arrow(d, done_bottom, (790, 920)); d.text((810, 875), "No", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (1040, 890, 1410, 1060), "SharedPreferences\nroutine configs +\nactive session"); arrow(d, (960, 975), (1040, 975)); connector(d, (1500, 975), "H"); arrow(d, (1410, 975), (1458, 975))

    # Profile/preferences/memory operations.
    d.line((70, 1110, 2930, 1110), fill="#D8D9D2", width=4); d.text((70, 1150), "SETTINGS AND AI MEMORY", font=lane_font, fill="#3C6E5A")
    connector(d, (110, 1280), "S")
    p_top, p_right, p_bottom, _ = decision(d, 380, 1205, 320, 150, "Profile changed?")
    l_top, l_right, l_bottom, l_left = decision(d, 1160, 1205, 340, 150, "Local preference changed?")
    m_top, m_right, m_bottom, m_left = decision(d, 1980, 1205, 340, 150, "Delete AI memory?")
    arrow(d, (152, 1280), p_top); route_arrow(d, [p_right, (990, p_right[1]), l_left]); d.text((800, p_right[1]-36), "No", font=pil_font(18, True), fill="#6B716C"); route_arrow(d, [l_right, (1810, l_right[1]), m_left]); d.text((1620, l_right[1]-36), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (230, 1410, 530, 1510), "UPSERT profiles on Save", PALE_GREEN, GREEN); arrow(d, p_bottom, (380, 1410)); d.text((400, 1365), "Yes", font=pil_font(18, True), fill="#6B716C"); connector(d, (620, 1460), "H"); arrow(d, (530, 1460), (578, 1460))
    process_box(d, (1010, 1410, 1310, 1510), "Write preferences to device", PALE_YELLOW, "#8A7213"); arrow(d, l_bottom, (1160, 1410)); d.text((1180, 1365), "Yes", font=pil_font(18, True), fill="#6B716C"); connector(d, (1400, 1460), "H"); arrow(d, (1310, 1460), (1358, 1460))
    process_box(d, (1830, 1410, 2130, 1510), "DELETE user_memories after confirmation", "#FBE8E8", "#9A3E3E"); arrow(d, m_bottom, (1980, 1410)); d.text((2000, 1365), "Yes", font=pil_font(18, True), fill="#6B716C"); connector(d, (2220, 1460), "H"); arrow(d, (2130, 1460), (2178, 1460))
    process_box(d, (2270, 1225, 2520, 1335), "No settings write", "#FFFFFF", MUTED); arrow(d, m_right, (2270, m_right[1])); d.text((2200, m_right[1]-36), "No", font=pil_font(18, True), fill="#6B716C"); connector(d, (2610, 1280), "H"); arrow(d, (2520, 1280), (2568, 1280))

    # Local-only provider persistence.
    d.line((70, 1580, 2930, 1580), fill="#D8D9D2", width=4); d.text((70, 1620), "LOCAL GOALS, LEARNING, AND REFLECTION", font=lane_font, fill="#3C6E5A")
    connector(d, (110, 1760), "L")
    g_top, g_right, g_bottom, _ = decision(d, 390, 1685, 340, 150, "Daily goal changed?")
    lr_top, lr_right, lr_bottom, lr_left = decision(d, 1280, 1685, 380, 150, "Learning or reflection changed?")
    arrow(d, (152, 1760), g_top); route_arrow(d, [g_right, (1090, g_right[1]), lr_left]); d.text((900, g_right[1]-36), "No", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (240, 1870, 540, 1970), "Create, toggle, or reset daily goals", PALE_YELLOW, "#8A7213"); arrow(d, g_bottom, (390, 1870)); d.text((410, 1835), "Yes", font=pil_font(18, True), fill="#6B716C")
    process_box(d, (1130, 1870, 1430, 1970), "Save learning progress or weekly reflection", PALE_YELLOW, "#8A7213"); arrow(d, lr_bottom, (1280, 1870)); d.text((1300, 1835), "Yes", font=pil_font(18, True), fill="#6B716C")
    database_cylinder(d, (1540, 1665, 1940, 1845), "SharedPreferences\ndaily goals + learning\n+ weekly reflections"); arrow(d, lr_right, (1540, lr_right[1])); d.text((1470, lr_right[1]-36), "No", font=pil_font(18, True), fill="#6B716C")
    connector(d, (2030, 1760), "H"); arrow(d, (1940, 1760), (1988, 1760))
    d.text((2050, 1690), "Current runtime: daily_goals and routine_configs save to SharedPreferences;", font=pil_font(19, True), fill="#9A5D00")
    d.text((2050, 1725), "the similarly named Supabase schema tables are not written by current providers.", font=pil_font(19, True), fill="#9A5D00")
    image.save(path, quality=96)


def erd_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], name: str,
            fields: list[tuple[str, str]], accent: str = "#3C6E5A") -> None:
    x1, y1, x2, y2 = box
    accent = css(accent)
    draw.rounded_rectangle(box, radius=16, fill="#FFFFFF", outline=accent, width=5)
    header_h = 62
    draw.rounded_rectangle((x1, y1, x2, y1 + header_h), radius=16, fill=accent, outline=accent, width=4)
    draw.rectangle((x1, y1 + 32, x2, y1 + header_h), fill=accent)
    title_font = pil_font(27, True)
    tw = draw.textbbox((0, 0), name, font=title_font)[2]
    draw.text((x1 + (x2 - x1 - tw) / 2, y1 + 14), name, font=title_font, fill="#FFFFFF")
    row_font = pil_font(22)
    key_font = pil_font(21, True)
    y = y1 + header_h + 15
    for key, field in fields:
        if key:
            draw.text((x1 + 16, y), key, font=key_font, fill=accent)
        draw.text((x1 + 88, y), field, font=row_font, fill="#242724")
        y += 34


def _draw_segment(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int],
                  color: str, width: int, dashed: bool) -> None:
    if not dashed:
        draw.line([start, end], fill=color, width=width)
        return
    import math
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dy)
    if length == 0:
        return
    ux, uy = dx / length, dy / length
    offset = 0.0
    while offset < length:
        segment_end = min(offset + 15, length)
        draw.line(
            [(start[0] + ux * offset, start[1] + uy * offset),
             (start[0] + ux * segment_end, start[1] + uy * segment_end)],
            fill=color,
            width=width,
        )
        offset += 25


def _cardinality_marker(draw: ImageDraw.ImageDraw, endpoint: tuple[int, int],
                        neighbor: tuple[int, int], cardinality: str,
                        color: str, width: int = 5) -> None:
    import math
    dx, dy = neighbor[0] - endpoint[0], neighbor[1] - endpoint[1]
    length = math.hypot(dx, dy)
    if length == 0:
        return
    ux, uy = dx / length, dy / length
    px, py = -uy, ux

    def point(distance: float, perpendicular: float = 0) -> tuple[float, float]:
        return (endpoint[0] + ux * distance + px * perpendicular,
                endpoint[1] + uy * distance + py * perpendicular)

    if cardinality in ("one", "zero_one"):
        for distance in ((10, 23) if cardinality == "one" else (10,)):
            center = point(distance)
            draw.line([point(distance, -11), point(distance, 11)], fill=color, width=width)
        if cardinality == "zero_one":
            center = point(29)
            draw.ellipse((center[0] - 8, center[1] - 8, center[0] + 8, center[1] + 8),
                         fill="#FFFDF8", outline=color, width=width)
        return

    # Crow's foot for one-or-many / zero-or-many / many.
    vertex = point(7)
    for perpendicular in (-13, 0, 13):
        draw.line([vertex, point(30, perpendicular)], fill=color, width=width)
    if cardinality == "zero_many":
        center = point(43)
        draw.ellipse((center[0] - 8, center[1] - 8, center[0] + 8, center[1] + 8),
                     fill="#FFFDF8", outline=color, width=width)
    elif cardinality == "one_many":
        draw.line([point(40, -11), point(40, 11)], fill=color, width=width)


def relationship(draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int],
                 points: list[tuple[int, int]] | None = None,
                 start_card: str = "one", end_card: str = "zero_many",
                 dashed: bool = False, color: str = "#686D69") -> None:
    path = [start] + (points or []) + [end]
    for first, second in zip(path, path[1:]):
        _draw_segment(draw, first, second, color, 5, dashed)
    _cardinality_marker(draw, start, path[1], start_card, color)
    _cardinality_marker(draw, end, path[-2], end_card, color)


def draw_erd(path: Path) -> None:
    image = Image.new("RGB", (2500, 1650), "#FFFDF8")
    d = ImageDraw.Draw(image)
    d.text((90, 45), "KAIBIGAN ENTITY RELATIONSHIP DIAGRAM", font=pil_font(48, True), fill="#242724")
    d.text((90, 108), "Supabase/PostgreSQL model • Crow's-foot cardinality • per-user Row Level Security",
           font=pil_font(25), fill="#6B716C")

    boxes = {
        "auth.users": (1010, 175, 1490, 330),
        "profiles": (940, 405, 1560, 705),
        "journal_entries": (70, 220, 650, 600),
        "gratitude_entries": (70, 700, 650, 1045),
        "mood_logs": (70, 1145, 650, 1510),
        "future_letters": (730, 1120, 1210, 1510),
        "daily_goals": (1290, 1120, 1770, 1510),
        "routine_configs": (1850, 220, 2430, 600),
        "routine_logs": (1850, 700, 2430, 1045),
        "user_memories": (1850, 1145, 2430, 1510),
    }

    erd_box(d, boxes["auth.users"], "auth.users (Supabase Auth)", [("PK", "id : uuid"), ("", "email / provider identity")], BLUE)
    erd_box(d, boxes["profiles"], "profiles", [("PK", "id : uuid"), ("", "logical id = auth.uid()"), ("", "email / display_name"), ("", "preferred_mascot_id"), ("", "preferred_language"), ("", "created_at / updated_at")], GREEN)
    erd_box(d, boxes["journal_entries"], "journal_entries", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "title / content"), ("", "ai_response"), ("", "reflection_mode / mood"), ("", "tags / is_favorite"), ("", "created_at / updated_at")], GREEN)
    erd_box(d, boxes["gratitude_entries"], "gratitude_entries", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "content / flower_type"), ("", "water_count"), ("", "garden_index / plot_index"), ("UQ", "user + garden + plot"), ("", "created_at")], GREEN)
    erd_box(d, boxes["mood_logs"], "mood_logs", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "mood_score / mood_label"), ("", "stress / energy"), ("", "sleep_quality / anxiety"), ("", "note / created_at")], GREEN)
    erd_box(d, boxes["future_letters"], "future_letters", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "title / content"), ("", "deliver_at"), ("", "is_opened"), ("", "created_at")], GREEN)
    erd_box(d, boxes["daily_goals"], "daily_goals", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "goal_type / title"), ("", "is_completed"), ("", "completed_at"), ("", "created_at")], GREEN)
    erd_box(d, boxes["routine_configs"], "routine_configs", [("PK", "id : text"), ("FK", "user_id : uuid"), ("", "title / subtitle"), ("", "routine_type"), ("", "reminder_time"), ("", "is_enabled / created_at")], GREEN)
    erd_box(d, boxes["routine_logs"], "routine_logs", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "routine_id / routine_type"), ("", "sleep_feeling / focus"), ("", "mood_score / note"), ("", "gratitude_content"), ("", "completed_at")], GREEN)
    erd_box(d, boxes["user_memories"], "user_memories", [("PK", "id : uuid"), ("FK", "user_id : uuid"), ("", "memory_category"), ("", "memory_summary"), ("", "relevance_score"), ("", "created_at / updated_at")], GREEN)

    # Logical identity relationship. It is implied by auth.uid() = profiles.id,
    # but the provided SQL does not declare profiles.id as an auth.users FK.
    relationship(d, (1250, 330), (1250, 405), start_card="one", end_card="zero_one", dashed=True)
    d.text((1280, 356), "logical identity", font=pil_font(17, True), fill="#686D69")

    # Every public child table contains user_id -> profiles.id (ON DELETE CASCADE).
    relationship(d, (940, 520), (650, 410), points=[(790, 520), (790, 410)])
    relationship(d, (940, 585), (650, 860), points=[(760, 585), (760, 860)])
    relationship(d, (940, 645), (650, 1335), points=[(700, 645), (700, 1335)])
    relationship(d, (1120, 705), (970, 1120), points=[(1120, 900), (970, 900)])
    relationship(d, (1380, 705), (1530, 1120), points=[(1380, 900), (1530, 900)])
    relationship(d, (1560, 520), (1850, 410), points=[(1710, 520), (1710, 410)])
    relationship(d, (1560, 585), (1850, 860), points=[(1740, 585), (1740, 860)])
    relationship(d, (1560, 645), (1850, 1335), points=[(1800, 645), (1800, 1335)])

    # routine_logs.routine_id logically refers to routine_configs.id, but the
    # current SQL stores it as TEXT without a declared foreign-key constraint.
    relationship(d, (2140, 600), (2140, 700), start_card="one", end_card="zero_many", dashed=True)
    d.text((2165, 635), "routine_id (logical)", font=pil_font(17, True), fill="#686D69")

    # Cardinality legend. Many-to-many is shown as notation only because the
    # current schema contains no junction table.
    d.rounded_rectangle((70, 1535, 2430, 1635), radius=16, fill="#FFF6CC", outline="#D5B533", width=3)
    relationship(d, (120, 1585), (230, 1585), start_card="one", end_card="zero_one")
    d.text((250, 1567), "1 to 0..1", font=pil_font(19, True), fill="#242724")
    relationship(d, (520, 1585), (630, 1585), start_card="one", end_card="zero_many")
    d.text((650, 1567), "1 to 0..many", font=pil_font(19, True), fill="#242724")
    relationship(d, (1050, 1585), (1160, 1585), start_card="many", end_card="many")
    d.text((1180, 1567), "many to many (junction table; none in current schema)",
           font=pil_font(18, True), fill="#242724")
    relationship(d, (2020, 1585), (2130, 1585), start_card="one", end_card="zero_many", dashed=True)
    d.text((2150, 1567), "logical / not enforced", font=pil_font(18, True), fill="#242724")

    image.save(path, quality=96)


def add_picture_with_alt(paragraph, image_path: Path, width: Inches, alt_text: str) -> None:
    run = paragraph.add_run()
    inline = run.add_picture(str(image_path), width=width)
    doc_pr = inline._inline.docPr
    doc_pr.set("descr", alt_text)


def configure_styles(doc: Document) -> None:
    styles = doc.styles
    normal = styles["Normal"]
    set_style_font(normal, "Arial", 10.5, INK)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.22

    for name, size, color, before, after in [
        ("Title", 29, INK, 0, 8),
        ("Subtitle", 13.5, MUTED, 0, 12),
        ("Heading 1", 17, GREEN, 17, 8),
        ("Heading 2", 13.5, GREEN, 12, 6),
        ("Heading 3", 11.5, BLUE, 9, 4),
    ]:
        style = styles[name]
        set_style_font(style, "Arial", size, color, bold=name != "Subtitle")
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True

    if "List Body" not in styles:
        style = styles.add_style("List Body", WD_STYLE_TYPE.PARAGRAPH)
    else:
        style = styles["List Body"]
    set_style_font(style, "Arial", 10.5, INK)
    style.paragraph_format.space_after = Pt(4)
    style.paragraph_format.line_spacing = 1.18

    if "Figure Caption" not in styles:
        style = styles.add_style("Figure Caption", WD_STYLE_TYPE.PARAGRAPH)
    else:
        style = styles["Figure Caption"]
    set_style_font(style, "Arial", 9, MUTED, False)
    style.font.italic = True
    style.paragraph_format.space_before = Pt(5)
    style.paragraph_format.space_after = Pt(5)
    style.paragraph_format.keep_with_next = False


def add_cover(doc: Document) -> None:
    section = doc.sections[0]
    section.top_margin = Inches(0.75)
    section.bottom_margin = Inches(0.65)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    section.header_distance = Inches(0.35)
    section.footer_distance = Inches(0.35)
    section.different_first_page_header_footer = True
    section.first_page_header.paragraphs[0].clear()
    section.first_page_footer.paragraphs[0].clear()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(16)
    add_picture_with_alt(p, LOGO_PATH, Inches(1.22), "Kaibigan bee companion logo")

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(13)
    r = p.add_run("PROJECT DOCUMENTATION")
    set_run_font(r, 10, True, GREEN)
    r.font.letter_spacing = Pt(1.2)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run("KAIBIGAN")
    set_run_font(r, 30, True, INK)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(24)
    r = p.add_run("An AI-Assisted Localized Mental Wellness Companion for Filipinos")
    set_run_font(r, 14, False, MUTED)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.left_indent = Inches(0.4)
    p.paragraph_format.right_indent = Inches(0.4)
    p.paragraph_format.space_after = Pt(25)
    set_cell_like_fill(p, PALE_YELLOW, YELLOW)
    r = p.add_run("A private, culturally responsive space for reflection, everyday self-care, and gentle support - built with Flutter, Supabase, and an optional AI reflection companion.")
    set_run_font(r, 11, False, INK)

    for label, value in [
        ("Technology", "Flutter • Provider • Supabase/PostgreSQL • Supabase Edge Functions"),
        ("AI Providers", "Google Gemini (primary) • Groq (fallback)"),
        ("Version", "1.0.0+1 • Repository snapshot: 31 August 2026"),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(4)
        r = p.add_run(f"{label}: ")
        set_run_font(r, 9.5, True, GREEN)
        r = p.add_run(value)
        set_run_font(r, 9.5, False, MUTED)

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(40)
    p.paragraph_format.space_after = Pt(0)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("Prepared from the current Kaibigan codebase")
    set_run_font(r, 9, False, MUTED, True)


def add_main_content(doc: Document, ordered_id: int, bullet_id: int) -> None:
    doc.add_page_break()
    doc.add_heading("1. Project Title and Description", level=1)
    add_label(doc, "Project Title")
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(10)
    r = p.add_run("Kaibigan: An AI-Assisted Localized Mental Wellness Companion for Filipinos")
    set_run_font(r, 12.5, True, INK)

    add_label(doc, "Project Description")
    add_body(doc, "Kaibigan is a cross-platform mental wellness application designed as a cozy, private journaling and self-care companion for Filipino users. It responds to a common gap in digital wellness tools: many products feel clinical, culturally distant, or focused on streaks and performance rather than reflection. Kaibigan instead combines English and Filipino language support, a warm visual system, and low-pressure activities that help users notice emotions, record meaningful moments, and build sustainable routines.", True)
    add_body(doc, "The application is built in Flutter with Provider-based state management. Supabase supplies authentication, PostgreSQL persistence, Row Level Security, and an authenticated Edge Function for production AI requests. Core experiences include an AI-assisted journal, mood and sleep tracking, a gratitude garden, future letters, daily and weekly reflections, guided breathing and grounding, affirmations, customizable routines, mental-health learning content, unified entries, profile preferences, and PDF export.", True)
    add_body(doc, "The AI companion is optional and does not control whether a journal entry can be written or saved. Before an AI request is sent, the application applies input limits and crisis-oriented guardrails. In production, the authenticated Edge Function attempts Google Gemini first and uses Groq as a fallback, returns a structured reflection response, and avoids logging journal content or model output. Long-term AI memories can be viewed and removed by the user.", True)
    add_note(doc, "Positioning", "Kaibigan is a reflection and self-care companion, not a therapist, diagnostic system, emergency service, or substitute for professional mental-health care.")

    doc.add_heading("2. Project Objectives Defined", level=1)
    add_label(doc, "General Objective")
    add_body(doc, "To design, develop, and evaluate Kaibigan as a secure, culturally responsive, and engaging mobile wellness companion that helps Filipino users practice emotional reflection, daily self-care, and healthy routine-building through localized content, private cloud-synced records, and optional AI-assisted guidance.")

    add_label(doc, "Specific Objectives")
    objectives = [
        "To provide a private journal with full create, read, update, delete, favorite, tag, and PDF-export capabilities, while keeping writing and saving independent from AI generation.",
        "To integrate an optional AI reflection companion that offers structured, empathetic responses, supports user-controlled memory, detects crisis-related language, and routes urgent cases toward immediate human help.",
        "To implement mood, stress, energy, anxiety, sleep, gratitude, focus, highlight, and reflection activities that help users notice patterns without presenting clinical diagnoses.",
        "To support morning, midday, night, and custom routines with progressive steps, reminders, completion logs, and resumable sessions.",
        "To offer bilingual English/Filipino presentation, light and dark themes, adjustable journal and garden appearance, accessible mobile layouts, and a warm Filipino-inspired interface.",
        "To secure per-user records through Supabase authentication, PostgreSQL foreign keys, and Row Level Security policies, while providing sensible local storage for selected preferences and progress.",
        "To provide trusted mental-health learning content, grounding and breathing exercises, affirmations, future letters, weekly reflection, and adaptive recommendations in one coherent home experience.",
    ]
    for item in objectives:
        add_list_item(doc, item, ordered_id)

    doc.add_heading("3. Scope and Limitations Identified", level=1)
    add_label(doc, "System Scope (In-Scope)")
    add_list_item(doc, "Target Audience: Filipino adolescents and adults seeking a gentle personal tool for journaling, mood awareness, self-care routines, and psychoeducational support.", ordered_id, bold_lead="Target Audience:")
    add_list_item(doc, "Platforms: Flutter targets Android, iOS, web, and compatible desktop development environments, with responsive layouts and touch, mouse, trackpad, and stylus input.", ordered_id, bold_lead="Platforms:")
    add_list_item(doc, "Authentication and Profile: Email/password registration and sign-in, password recovery, optional Google OAuth, profile settings, mascot preference, theme mode, and English/Filipino language selection.", ordered_id, bold_lead="Authentication and Profile:")
    add_list_item(doc, "Home and Adaptive Support: A single home surface loads recent records, presents routine progress and activity cards, and recommends check-in, grounding, breathing, reflection, gratitude, or focus activities from current user context.", ordered_id, bold_lead="Home and Adaptive Support:")
    add_list_item(doc, "AI Journal and Reflection: Journal CRUD, drafts, conversation-style AI responses, reflection modes, mood and tags, favorites, save summaries, user feedback, user-controlled AI memories, and PDF export.", ordered_id, bold_lead="AI Journal and Reflection:")
    add_list_item(doc, "Tracking and Memory Activities: Mood logs, sleep logs, gratitude entries visualized as flowers across 15-plot gardens, daily goals, today’s focus, today’s highlight, daily reflection, weekly reflection, and a unified entries timeline.", ordered_id, bold_lead="Tracking and Memory Activities:")
    add_list_item(doc, "Self-Care and Learning: 5-4-3-2-1 grounding, paced breathing and mindfulness sessions, affirmations, future letters, a comfort corner, localized learning paths, and trusted MedlinePlus article discovery.", ordered_id, bold_lead="Self-Care and Learning:")
    add_list_item(doc, "Routines and Reminders: Default morning, midday, and night routines; custom routine configuration; progressive activity execution; resumable sessions; completion logs; and local notification support.", ordered_id, bold_lead="Routines and Reminders:")
    add_list_item(doc, "Cloud Data and Security: Supabase Auth, PostgreSQL tables, per-user Row Level Security, authenticated Edge Function access, bounded AI input, provider fallback, and non-logging of journal/model content.", ordered_id, bold_lead="Cloud Data and Security:")

    add_label(doc, "System Limitations (Out-of-Scope)")
    limitations = [
        "Clinical Care: Kaibigan does not diagnose conditions, provide psychotherapy, create treatment plans, monitor medication, or replace a licensed professional or emergency service.",
        "Emergency Response: Crisis language can trigger supportive messaging and Philippine emergency resources, but the system cannot contact responders, verify a user’s safety, or continuously monitor risk.",
        "Internet Dependency: Authentication, cloud synchronization, AI responses, password recovery, OAuth, and online article discovery require network access. Selected preferences and learning progress may remain local, but the application is not a complete offline-first system.",
        "AI Uncertainty: Gemini and Groq outputs may be incomplete or inaccurate. Availability, latency, and response quality depend on third-party services and configured API quotas.",
        "Privacy Boundary: Row Level Security protects server-side records, but client builds still require responsible configuration. Direct demo AI keys embedded through compile-time defines are recoverable and must not be used for production publishing.",
        "User Model: The current release focuses on one private end user per account. Clinician dashboards, caregiver access, peer communities, classroom management, and organization-level administration are excluded.",
        "Devices and Integrations: The current scope does not include wearable sensor ingestion, clinical-record integration, telehealth sessions, location tracking, camera/OCR analysis, or automated health scoring.",
        "Notification Constraints: Reminder behavior depends on platform permissions and operating-system scheduling; delivery at an exact time is not guaranteed on every device.",
    ]
    for item in limitations:
        add_list_item(doc, item, bullet_id)


def add_diagram_sections(doc: Document) -> None:
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    section.different_first_page_header_footer = False
    section.orientation = WD_ORIENT.PORTRAIT
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.55)
    section.bottom_margin = Inches(0.55)
    section.left_margin = Inches(0.75)
    section.right_margin = Inches(0.75)
    section.header_distance = Inches(0.25)
    section.footer_distance = Inches(0.25)
    set_repeat_header_text(section, "Kaibigan", "Project Documentation")
    set_footer(section)

    doc.add_heading("4. Updated System Flowchart", level=1)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(5)
    r = p.add_run("The linked flowcharts separate authentication and navigation from journal CRUD, AI assistance, cloud persistence, and device-only persistence. Every decision has exactly two exits: Yes and No.")
    set_run_font(r, 9.5, False, MUTED)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    add_picture_with_alt(p, FLOW_PATH, Inches(5.65), "Part 1 conventional Kaibigan flowchart showing authentication, initial Supabase reads, and sequential feature routing with Yes and No exits")
    caption = doc.add_paragraph(style="Figure Caption")
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.add_run("Figure 1. Part 1 — authentication, initial database reads, and feature routing.")

    section = doc.add_section(WD_SECTION.NEW_PAGE)
    section.different_first_page_header_footer = False
    section.orientation = WD_ORIENT.LANDSCAPE
    section.page_width = Inches(11)
    section.page_height = Inches(8.5)
    section.top_margin = Inches(0.55)
    section.bottom_margin = Inches(0.55)
    section.left_margin = Inches(0.65)
    section.right_margin = Inches(0.65)
    section.header_distance = Inches(0.25)
    section.footer_distance = Inches(0.25)
    set_repeat_header_text(section, "Kaibigan", "Project Documentation")
    set_footer(section)

    doc.add_heading("4.2 Journal CRUD and AI Assistance", level=2)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run("This continuation shows every journal create, read, update, delete, and favorite operation; the optional authenticated AI path; Gemini-to-Groq fallback; and the exact journal and memory writes.")
    set_run_font(r, 9.5, False, MUTED)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(2)
    add_picture_with_alt(p, JOURNAL_FLOW_PATH, Inches(9.25), "Part 2 flowchart showing journal CRUD, optional AI safety checks, Gemini and Groq fallback, journal_entries saves, and user_memories inserts")
    caption = doc.add_paragraph(style="Figure Caption")
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.add_run("Figure 2. Part 2 — journal CRUD, AI assistance, fallback behavior, and cloud save points.")

    doc.add_page_break()
    doc.add_heading("4.3 Other CRUD and Persistence", level=2)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run("This continuation identifies CRUD for mood, gratitude, future letters, routine logs, profiles, and AI memories, while distinguishing Supabase writes from SharedPreferences device writes.")
    set_run_font(r, 9.5, False, MUTED)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(2)
    add_picture_with_alt(p, PERSISTENCE_FLOW_PATH, Inches(9.25), "Part 3 flowchart showing other CRUD operations, named Supabase tables, SharedPreferences storage, and exact save triggers")
    caption = doc.add_paragraph(style="Figure Caption")
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.add_run("Figure 3. Part 3 — other CRUD operations and cloud versus device persistence.")

    doc.add_page_break()
    doc.add_heading("5. Entity Relationship Diagram", level=1)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run("Crow's-foot connectors show the logical one-to-zero/one identity link and the database-enforced one-to-many ownership relationships. Solid lines represent declared foreign keys; dashed lines represent logical links that are not enforced by the current SQL. No many-to-many junction table exists in the present schema.")
    set_run_font(r, 9.5, False, MUTED)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(1)
    p.paragraph_format.space_after = Pt(2)
    add_picture_with_alt(p, ERD_PATH, Inches(9.05), "Crow's-foot entity relationship diagram showing one-to-zero-or-one, one-to-many, and dashed logical relationships among Supabase Auth, profiles, routine configurations, and per-user data tables")
    caption = doc.add_paragraph(style="Figure Caption")
    caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.add_run("Figure 4. Kaibigan ERD using Crow's-foot cardinality. Many-to-many notation appears in the legend only because the current schema has no junction table.")


def build_document() -> None:
    draw_navigation_flowchart(FLOW_PATH)
    draw_journal_flowchart_clean(JOURNAL_FLOW_PATH)
    draw_persistence_flowchart_clean(PERSISTENCE_FLOW_PATH)
    draw_erd(ERD_PATH)

    doc = Document()
    configure_styles(doc)
    doc.core_properties.title = "Kaibigan Project Documentation"
    doc.core_properties.subject = "Project description, objectives, scope, limitations, system flowchart, and ERD"
    doc.core_properties.author = "Kaibigan Project Team"
    doc.core_properties.keywords = "Kaibigan, Flutter, Supabase, mental wellness, documentation"
    doc.core_properties.comments = "Generated from the Kaibigan repository structure and implementation."

    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.7)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    set_repeat_header_text(section, "Kaibigan", "Project Documentation")
    set_footer(section)

    ordered_id = add_numbering_definition(doc, ordered=True)
    bullet_id = add_numbering_definition(doc, ordered=False)

    add_cover(doc)
    add_main_content(doc, ordered_id, bullet_id)
    add_diagram_sections(doc)
    doc.save(DOCX_PATH)
    print(DOCX_PATH)


if __name__ == "__main__":
    build_document()
