from __future__ import annotations

from html import escape
from pathlib import Path

from docx import Document
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import LETTER, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    Image,
    ListFlowable,
    ListItem,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
)


ROOT = Path(__file__).resolve().parents[1]
DOCX_PATH = ROOT / "output" / "Kaibigan_Project_Documentation_ERD_Updated.docx"
PDF_PATH = ROOT / "output" / "Kaibigan_Project_Documentation_ERD_Updated.pdf"
LOGO_PATH = ROOT / "kaibigan_flutter" / "assets" / "Kaibigan Logo.png"
FLOW_PATH = ROOT / "tmp" / "docs" / "kaibigan_documentation" / "kaibigan_system_flowchart.png"
JOURNAL_FLOW_PATH = ROOT / "tmp" / "docs" / "kaibigan_documentation" / "kaibigan_journal_ai_crud_flowchart.png"
PERSISTENCE_FLOW_PATH = ROOT / "tmp" / "docs" / "kaibigan_documentation" / "kaibigan_other_crud_persistence_flowchart.png"
ERD_PATH = ROOT / "tmp" / "docs" / "kaibigan_documentation" / "kaibigan_erd.png"


GREEN = colors.HexColor("#3C6E5A")
BLUE = colors.HexColor("#426A83")
INK = colors.HexColor("#242724")
MUTED = colors.HexColor("#6B716C")
YELLOW = colors.HexColor("#FFD21F")
PALE_YELLOW = colors.HexColor("#FFF6CC")
LINE = colors.HexColor("#D8D9D2")


def register_fonts() -> None:
    font_dir = Path("C:/Windows/Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(font_dir / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Bold", str(font_dir / "arialbd.ttf")))
    pdfmetrics.registerFont(TTFont("Arial-Italic", str(font_dir / "ariali.ttf")))


def draw_header_footer(canvas, doc) -> None:
    canvas.saveState()
    width, height = canvas._pagesize
    canvas.setFont("Arial-Bold", 8.5)
    canvas.setFillColor(GREEN)
    canvas.drawString(doc.leftMargin, height - 0.37 * inch, "KAIBIGAN")
    canvas.setFont("Arial", 8.5)
    canvas.setFillColor(MUTED)
    canvas.drawRightString(width - doc.rightMargin, height - 0.37 * inch, "Project Documentation")
    canvas.setStrokeColor(LINE)
    canvas.setLineWidth(0.55)
    canvas.line(doc.leftMargin, height - 0.45 * inch, width - doc.rightMargin, height - 0.45 * inch)
    canvas.setFont("Arial", 8.5)
    canvas.setFillColor(MUTED)
    canvas.drawRightString(width - doc.rightMargin, 0.32 * inch, f"Page {doc.page}")
    canvas.restoreState()


def draw_cover(canvas, doc) -> None:
    canvas.saveState()
    width, height = canvas._pagesize
    canvas.setFillColor(colors.HexColor("#FFF9ED"))
    canvas.rect(0, 0, width, height, stroke=0, fill=1)
    canvas.setFillColor(YELLOW)
    canvas.rect(0, height - 0.16 * inch, width, 0.16 * inch, stroke=0, fill=1)
    canvas.restoreState()


def styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "cover_kicker": ParagraphStyle("cover_kicker", parent=base["Normal"], fontName="Arial-Bold", fontSize=10,
            leading=13, textColor=GREEN, alignment=TA_CENTER, spaceAfter=12),
        "cover_title": ParagraphStyle("cover_title", parent=base["Normal"], fontName="Arial-Bold", fontSize=30,
            leading=34, textColor=INK, alignment=TA_CENTER, spaceAfter=8),
        "cover_subtitle": ParagraphStyle("cover_subtitle", parent=base["Normal"], fontName="Arial", fontSize=14,
            leading=19, textColor=MUTED, alignment=TA_CENTER, spaceAfter=22),
        "cover_callout": ParagraphStyle("cover_callout", parent=base["Normal"], fontName="Arial", fontSize=11,
            leading=16, textColor=INK, alignment=TA_CENTER, backColor=PALE_YELLOW, borderColor=YELLOW,
            borderWidth=0.8, borderPadding=12, borderRadius=5, leftIndent=24, rightIndent=24, spaceAfter=22),
        "cover_meta": ParagraphStyle("cover_meta", parent=base["Normal"], fontName="Arial", fontSize=9.5,
            leading=13, textColor=MUTED, alignment=TA_CENTER, spaceAfter=4),
        "cover_note": ParagraphStyle("cover_note", parent=base["Normal"], fontName="Arial-Italic", fontSize=9,
            leading=12, textColor=MUTED, alignment=TA_CENTER),
        "h1": ParagraphStyle("h1", parent=base["Heading1"], fontName="Arial-Bold", fontSize=17,
            leading=20, textColor=GREEN, spaceBefore=14, spaceAfter=8, keepWithNext=1),
        "label": ParagraphStyle("label", parent=base["Heading2"], fontName="Arial-Bold", fontSize=11.5,
            leading=14, textColor=GREEN, spaceBefore=6, spaceAfter=4, keepWithNext=1),
        "body": ParagraphStyle("body", parent=base["BodyText"], fontName="Arial", fontSize=10.3,
            leading=13.3, textColor=INK, alignment=TA_JUSTIFY, spaceAfter=6),
        "title_value": ParagraphStyle("title_value", parent=base["BodyText"], fontName="Arial-Bold", fontSize=12.5,
            leading=16, textColor=INK, spaceAfter=10),
        "list": ParagraphStyle("list", parent=base["BodyText"], fontName="Arial", fontSize=10,
            leading=12.8, textColor=INK, alignment=TA_LEFT, leftIndent=8, spaceAfter=3),
        "note": ParagraphStyle("note", parent=base["BodyText"], fontName="Arial", fontSize=9.4,
            leading=12.5, textColor=INK, backColor=PALE_YELLOW, borderColor=YELLOW, borderWidth=0.7,
            borderPadding=8, borderRadius=4, spaceBefore=6, spaceAfter=9),
        "diagram_intro": ParagraphStyle("diagram_intro", parent=base["BodyText"], fontName="Arial", fontSize=9.5,
            leading=12, textColor=MUTED, spaceAfter=5),
        "caption": ParagraphStyle("caption", parent=base["BodyText"], fontName="Arial-Italic", fontSize=8.8,
            leading=11, textColor=MUTED, alignment=TA_CENTER, spaceBefore=4),
    }


def bold_lead(text: str) -> str:
    if ":" not in text:
        return escape(text)
    lead, rest = text.split(":", 1)
    return f"<b>{escape(lead)}:</b>{escape(rest)}"


def build_pdf() -> None:
    register_fonts()
    s = styles()
    source = Document(DOCX_PATH)
    p = [paragraph.text.replace("•", "|") for paragraph in source.paragraphs]

    portrait_frame = Frame(0.86 * inch, 0.62 * inch, LETTER[0] - 1.72 * inch, LETTER[1] - 1.25 * inch,
                           leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="portrait_frame")
    landscape_size = landscape(LETTER)
    landscape_frame = Frame(0.63 * inch, 0.55 * inch, landscape_size[0] - 1.26 * inch,
                            landscape_size[1] - 1.08 * inch, leftPadding=0, rightPadding=0,
                            topPadding=0, bottomPadding=0, id="landscape_frame")
    cover_frame = Frame(0.95 * inch, 0.65 * inch, LETTER[0] - 1.9 * inch, LETTER[1] - 1.3 * inch,
                        leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0, id="cover_frame")
    doc = BaseDocTemplate(str(PDF_PATH), pagesize=LETTER, leftMargin=0.86 * inch, rightMargin=0.86 * inch,
                          topMargin=0.62 * inch, bottomMargin=0.62 * inch,
                          title="Kaibigan Project Documentation", author="Kaibigan Project Team",
                          subject="Project description, objectives, scope, limitations, system flowchart, and ERD")
    doc.addPageTemplates([
        PageTemplate(id="cover", pagesize=LETTER, frames=[cover_frame], onPage=draw_cover),
        PageTemplate(id="portrait", pagesize=LETTER, frames=[portrait_frame], onPage=draw_header_footer),
        PageTemplate(id="landscape", pagesize=landscape_size, frames=[landscape_frame], onPage=draw_header_footer),
    ])

    story = [
        Spacer(1, 0.32 * inch),
        Image(str(LOGO_PATH), width=1.18 * inch, height=1.18 * inch, hAlign="CENTER"),
        Spacer(1, 0.17 * inch),
        Paragraph(escape(p[1]), s["cover_kicker"]),
        Paragraph(escape(p[2]), s["cover_title"]),
        Paragraph(escape(p[3]), s["cover_subtitle"]),
        Paragraph(escape(p[4]), s["cover_callout"]),
    ]
    for i in (5, 6, 7):
        label, value = p[i].split(":", 1)
        story.append(Paragraph(f"<b><font color='#3C6E5A'>{escape(label)}:</font></b>{escape(value)}", s["cover_meta"]))
    story.extend([Spacer(1, 0.47 * inch), Paragraph(escape(p[8]), s["cover_note"]), NextPageTemplate("portrait"), PageBreak()])

    for idx in range(10, 49):
        text = p[idx]
        if not text:
            continue
        if idx in (10, 18, 29):
            story.append(Paragraph(escape(text), s["h1"]))
        elif idx in (11, 13, 19, 21, 30, 40):
            story.append(Paragraph(escape(text), s["label"]))
        elif idx == 12:
            story.append(Paragraph(escape(text), s["title_value"]))
        elif idx == 17:
            story.append(Paragraph(bold_lead(text), s["note"]))
        elif 22 <= idx <= 28:
            # Objectives are collected below as one numbered list.
            if idx == 22:
                items = [ListItem(Paragraph(escape(p[j]), s["list"]), leftIndent=14) for j in range(22, 29)]
                story.append(ListFlowable(items, bulletType="1", start="1", leftIndent=22, bulletFontName="Arial",
                                          bulletFontSize=10, bulletColor=GREEN, spaceAfter=6))
        elif 31 <= idx <= 39:
            if idx == 31:
                items = [ListItem(Paragraph(bold_lead(p[j]), s["list"]), leftIndent=14) for j in range(31, 40)]
                story.append(ListFlowable(items, bulletType="1", start="1", leftIndent=22, bulletFontName="Arial",
                                          bulletFontSize=10, bulletColor=GREEN, spaceAfter=6))
        elif 41 <= idx <= 48:
            if idx == 41:
                items = [ListItem(Paragraph(bold_lead(p[j]), s["list"]), leftIndent=14) for j in range(41, 49)]
                story.append(ListFlowable(items, bulletType="bullet", bulletChar="•", leftIndent=22,
                                          bulletFontName="Arial", bulletFontSize=10, bulletColor=GREEN, spaceAfter=6))
        else:
            story.append(Paragraph(escape(text), s["body"]))

    story.extend([
        NextPageTemplate("portrait"), PageBreak(),
        Paragraph("4. Updated System Flowchart", s["h1"]),
        Paragraph("The linked flowcharts separate authentication and navigation from journal CRUD, AI assistance, cloud persistence, and device-only persistence. Every decision has exactly two exits: Yes and No.", s["diagram_intro"]),
        Image(str(FLOW_PATH), width=5.48 * inch, height=8.15 * inch, hAlign="CENTER"),
        Paragraph("Figure 1. Part 1 — authentication, initial database reads, and feature routing.", s["caption"]),
        NextPageTemplate("landscape"), PageBreak(),
        Paragraph("4.2 Journal CRUD and AI Assistance", s["label"]),
        Paragraph("This continuation shows every journal create, read, update, delete, and favorite operation; the optional authenticated AI path; Gemini-to-Groq fallback; and the exact journal and memory writes.", s["diagram_intro"]),
        Image(str(JOURNAL_FLOW_PATH), width=9.25 * inch, height=6.17 * inch, hAlign="CENTER"),
        Paragraph("Figure 2. Part 2 — journal CRUD, AI assistance, fallback behavior, and cloud save points.", s["caption"]),
        PageBreak(),
        Paragraph("4.3 Other CRUD and Persistence", s["label"]),
        Paragraph("This continuation identifies CRUD for mood, gratitude, future letters, routine logs, profiles, and AI memories, while distinguishing Supabase writes from SharedPreferences device writes.", s["diagram_intro"]),
        Image(str(PERSISTENCE_FLOW_PATH), width=9.25 * inch, height=6.17 * inch, hAlign="CENTER"),
        Paragraph("Figure 3. Part 3 — other CRUD operations and cloud versus device persistence.", s["caption"]),
        PageBreak(),
        Paragraph("5. Entity Relationship Diagram", s["h1"]),
        Paragraph("Crow's-foot connectors show the logical one-to-zero/one identity link and the database-enforced one-to-many ownership relationships. Solid lines represent declared foreign keys; dashed lines represent logical links that are not enforced by the current SQL. No many-to-many junction table exists in the present schema.", s["diagram_intro"]),
        Image(str(ERD_PATH), width=9.05 * inch, height=5.97 * inch, hAlign="CENTER"),
        Paragraph("Figure 4. Kaibigan ERD using Crow's-foot cardinality. Many-to-many notation appears in the legend only because the current schema has no junction table.", s["caption"]),
    ])
    doc.build(story)
    print(PDF_PATH)


if __name__ == "__main__":
    build_pdf()
