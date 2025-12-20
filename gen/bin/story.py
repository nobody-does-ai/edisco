#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate the Limited Objection PDF (review-mode: visible links).

Install on Debian/Devuan:
  sudo apt install python3-reportlab
"""

from reportlab.lib.pagesizes import LETTER
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

# --- Helpers: review-mode links + authorities collection ---

AUTHORITIES = []

def register_authority(*args, **kwargs):
    AUTHORITIES.append([args, kwargs])

def link(label, url):
    # REVIEW MODE: always visible
    return f'<link href="{url}"><u><font color="blue">{label}</font></u></link>'

def mcl_url(sec):
    # Michigan Legislature canonical pattern: objectName=mcl-700-7814
    return f"https://www.legislature.mi.gov/Laws/MCL?objectName=mcl-{sec.replace('.', '-')}"

def mcl_link(sec, sub=None):
    label = f"MCL {sec}" + (f"({sub})" if sub else "")
    url = mcl_url(sec)
    register_authority(kind="statute", system="MCL", sec=sec, sub=sub, label=label, url=url)
    return link(label, url)

story = []

def add(x,y=None):
    """
    Append a flowable (Paragraph, Spacer, etc.) to the story.
    This is a compatibility shim that can later be redefined
    to emit plain text instead of ReportLab objects.
    """
    story.append(Paragraph(x,y))

# --- Document text (includes good-faith vs indemnity paragraph) ---

def build_story():
    styles = getSampleStyleSheet()
    body = ParagraphStyle(
        "CustBody",
        parent=styles["BodyText"],
        fontName="Times-Roman",
        fontSize=11,
        leading=14,
        spaceAfter=10,
    )
    h1 = ParagraphStyle(
        "CustH1",
        parent=styles["Heading2"],
        fontName="Times-Bold",
        fontSize=12,
        leading=14,
        spaceBefore=8,
        spaceAfter=10,
    )
    center = ParagraphStyle(
        "CustCenter",
        parent=styles["BodyText"],
        alignment=1,
        fontName="Times-Bold",
        fontSize=12,
        leading=14,
        spaceAfter=10,
    )

    add("STATE OF MICHIGAN", center)
    add("PROBATE COURT – WASHTENAW COUNTY", center)
    story.append(Spacer(1, 0.15 * inch))

    add("<b>In the Matter of:</b><br/>"
                           "ARA G. PAUL AND SHIRLEY W. PAUL<br/>"
                           "CHARITABLE REMAINDER UNITRUST<br/>"
                           "DATED MAY 12, 2023", body)
    story.append(Spacer(1, 0.10 * inch))
    add("<b>Case No.:</b> 25-001332-TV<br/>"
                           "<b>Judge:</b> Hon. Darlene A. O’Brien", body)
    story.append(Spacer(1, 0.20 * inch))

    add("LIMITED OBJECTION TO PETITION FOR DIVISION OF TRUST", center)
    story.append(Spacer(1, 0.15 * inch))

    add(
        "Objector, <b>Richard Nobody Paul</b>, appearing <i>pro se</i>, submits this Limited Objection to the "
        "Petition for Division of Trust filed by John B. Paul and Lisa J. Paul, Co-Trustees, and states as follows:",
        body
    )

    add("I. INTEREST AND CONSENT", h1)
    add(
        f"1. Objector is a lifetime income beneficiary of the Trust and therefore an interested person under {mcl_link('700.1105', 'c')}.",
        body
    )
    add(
        f"2. Objector consents to the division of the Trust into two separate charitable remainder unitrusts as proposed in the Petition "
        f"and the attached Instrument of Division, as such division is authorized by the Trust instrument (Article II.A.5) and {mcl_link('700.7417')}, "
        f"and may facilitate more orderly administration going forward.",
        body
    )
    add("3. This Objection is limited and specific. Objector does not oppose division itself.", body)

    add("II. OBJECTION TO DISCHARGE AND RELEASE OF CO-TRUSTEES", h1)
    add(
        "4. Objector objects to Paragraph G of the Petition’s Prayer for Relief, which seeks to discharge the Co-Trustees "
        "“without liability to any person.”",
        body
    )
    add(
        "5. Such a discharge is premature, overbroad, and improper where: no final accounting has been rendered; material disputes exist "
        "regarding past administration; and beneficiaries have not been afforded full disclosure sufficient to evaluate trustee conduct.",
        body
    )
    add(
        f"6. Michigan law does not permit trustees to obtain a blanket discharge under these circumstances. Trustees owe ongoing duties of loyalty, "
        f"prudence, impartiality, and candor to beneficiaries, including a duty to furnish information reasonably necessary to protect beneficiary interests. "
        f"See {mcl_link('700.7801')}, {mcl_link('700.7814')}.",
        body
    )
    add(
        f"7. Where unresolved issues remain concerning administration, distributions, investment strategy, and professional fees, any order purporting to "
        f"discharge trustees would unlawfully prejudice beneficiary rights and improperly insulate fiduciaries from potential surcharge or other remedies. "
        f"See {mcl_link('700.7901')}–{mcl_link('700.7902')}.",
        body
    )
    add(
        "8. Objector further objects to any implied or express release of liability arising from the proposed division, resignation, or transfer of trusteeship. "
        "Division of a trust does not, by itself, extinguish existing fiduciary obligations or claims.",
        body
    )

    add(
        "9. The Trust instrument already provides substantial protection to the Trustees for the exercise or nonexercise of their powers when undertaken in good faith, "
        "expressly stating that such actions are conclusive upon all persons. This protection is consistent with Michigan law, which likewise shields trustees from liability "
        "for discretionary decisions made in good faith. Accordingly, the additional release, indemnification, and hold-harmless provisions sought by Petitioners would have "
        "operative effect only if applied to conduct outside the scope of good faith, including conduct as to which liability could not otherwise be waived under Michigan law. "
        "To the extent the requested relief seeks to extend protection beyond what the Trust instrument and governing law already provide, it is unnecessary, legally ineffective, "
        "and prejudicial to the interests of the beneficiaries. For this reason, approval of any blanket release or indemnification prior to a full accounting and resolution of "
        "disputed issues would be improper.",
        body
    )

    add("III.A. ADDITIONAL OBJECTION REGARDING THE INSTRUMENT OF DIVISION", h1)
    add(
        "10. Objector further notes that the proposed Instrument of Division (Exhibit D) contains provisions that mirror the same overbroad discharge and release of liability objected to above.",
        body
    )
    add(
        "11. Objector expressly advised Petitioners weeks prior to filing that he would not execute the Instrument of Division while it contained such a release, and his refusal was based solely on that provision.",
        body
    )
    add(
        "12. Petitioners’ decision to proceed with litigation rather than remove the offending release language from the Instrument of Division is the sole reason attorney fees are now being incurred.",
        body
    )
    add(
        "13. Accordingly, any attorney fees incurred in connection with drafting, defending, or attempting to enforce release or exculpatory language—whether in the Petition or the Instrument of Division—were not incurred for the benefit of the Trust, but to secure personal protection for the Co-Trustees, and are not properly chargeable to Trust assets.",
        body
    )

    add("IV. REQUESTED RELIEF", h1)
    add("WHEREFORE, Objector respectfully requests that the Court:", body)
    add("1. Summarily approve the division of the Trust as proposed, as there is no genuine controversy regarding the authority to divide the Trust or the mechanics of the proposed division;", body)
    add("2. Enter an order expressly providing that approval of the division is without prejudice to, and does not adjudicate, release, discharge, surcharge, or liability issues relating to the Co-Trustees;", body)
    add("3. Limit any remaining controversy in this proceeding to the discrete issues of: (a) whether the Co-Trustees are entitled to any discharge or release of liability; and (b) whether attorney fees incurred in connection with release or exculpatory provisions may properly be charged to Trust assets;", body)
    add("4. Order the immediate release and transfer of Trust funds to the successor Trustee(s) without further obstruction;", body)
    add("5. Grant such other and further relief as the Court deems just and proper.", body)

    add(Spacer(1, 0.20 * inch))
    add("<b>Respectfully submitted,</b>", body)
    add("Richard Nobody Paul<br/>Objector, <i>pro se</i><br/>[Address]<br/>[Telephone]<br/>[Email]", body)
    add("Date: December ___, 2025", body)

    return story

def build_pdf(pdf_path):
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=LETTER,
        leftMargin=1.0*inch,
        rightMargin=1.0*inch,
        topMargin=0.85*inch,
        bottomMargin=0.85*inch,
        title="Limited Objection to Petition for Division of Trust",
        author="Richard Nobody Paul",
    )
    doc.build(build_story())

def main():
    build_pdf("Limited_Objection_updated_goodfaith.pdf")
    # AUTHORITIES is available for future TOA generation, debugging, etc.
    # For now, we just discard it at exit.

if __name__ == "__main__":
    main()
