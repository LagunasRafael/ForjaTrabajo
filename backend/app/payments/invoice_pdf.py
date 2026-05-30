import os
import tempfile
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_RIGHT, TA_CENTER

def generate_invoice_pdf(payment_data: dict) -> str:
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "CustomTitle", parent=styles["Title"],
        fontSize=28, textColor=HexColor("#4F46E5"), spaceAfter=6
    )
    subtitle_style = ParagraphStyle(
        "Subtitle", parent=styles["Normal"],
        fontSize=10, textColor=HexColor("#64748B"), spaceAfter=20
    )
    label_style = ParagraphStyle(
        "Label", parent=styles["Normal"],
        fontSize=9, textColor=HexColor("#94A3B8"), spaceBefore=8, spaceAfter=2
    )
    value_style = ParagraphStyle(
        "Value", parent=styles["Normal"],
        fontSize=13, textColor=HexColor("#1E293B"), spaceAfter=10
    )
    section_style = ParagraphStyle(
        "Section", parent=styles["Heading2"],
        fontSize=14, textColor=HexColor("#1E293B"), spaceBefore=16, spaceAfter=8
    )
    total_label_style = ParagraphStyle(
        "TotalLabel", parent=styles["Normal"],
        fontSize=14, textColor=HexColor("#64748B")
    )
    total_value_style = ParagraphStyle(
        "TotalValue", parent=styles["Normal"],
        fontSize=22, textColor=HexColor("#4F46E5"), alignment=TA_RIGHT
    )

    now = datetime.now()
    invoice_id = payment_data.get("id", "N/A")[:8].upper()
    amount = payment_data.get("amount", 0)
    platform_fee = payment_data.get("platform_fee", 0)
    subtotal = amount - platform_fee
    service_title = payment_data.get("service_title") or "Servicio"
    service_desc = payment_data.get("service_description") or ""
    service_cat = payment_data.get("service_category") or ""
    status = payment_data.get("status", "").upper()

    status_map = {
        "RELEASED": "PAGADO", "COMPLETED": "PAGADO", "PAID": "PAGADO",
        "HELD_IN_ESCROW": "EN GARANTÍA",
        "PENDING_TRANSFER": "EN TRANSFERENCIA",
        "REFUNDED": "REEMBOLSADO",
        "PENDING": "PENDIENTE",
        "FAILED": "FALLIDO",
    }
    status_label = status_map.get(status, status)

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf")
    doc = SimpleDocTemplate(tmp.name, pagesize=letter,
                            topMargin=0.8*inch, bottomMargin=0.8*inch)

    elements = []

    elements.append(Paragraph("FORJA TRABAJO", title_style))
    elements.append(Paragraph("Factura Electrónica", subtitle_style))
    elements.append(Spacer(1, 12))

    elements.append(Paragraph("DATOS DEL SERVICIO", section_style))
    elements.append(Paragraph("Nombre del servicio", label_style))
    elements.append(Paragraph(service_title, value_style))

    if service_cat:
        elements.append(Paragraph("Categoría", label_style))
        elements.append(Paragraph(service_cat, value_style))

    if service_desc:
        elements.append(Paragraph("Descripción", label_style))
        elements.append(Paragraph(service_desc, value_style))

    elements.append(Spacer(1, 12))
    elements.append(Paragraph("DATOS DE FACTURACIÓN", section_style))
    elements.append(Paragraph("Factura", label_style))
    elements.append(Paragraph(f"#{invoice_id}", value_style))
    elements.append(Paragraph("Fecha", label_style))
    elements.append(Paragraph(now.strftime("%d de %B, %Y"), value_style))
    elements.append(Paragraph("Estado", label_style))
    elements.append(Paragraph(status_label, value_style))

    elements.append(Spacer(1, 20))

    detail_data = [
        [Paragraph("Subtotal", total_label_style),
         Paragraph(f"${subtotal:,.2f} MXN", ParagraphStyle("ValueRight", parent=styles["Normal"], fontSize=14, textColor=HexColor("#1E293B"), alignment=TA_RIGHT))],
        [Paragraph("Comisión Forja (5%)", total_label_style),
         Paragraph(f"${platform_fee:,.2f} MXN", ParagraphStyle("ValueRight", parent=styles["Normal"], fontSize=14, textColor=HexColor("#64748B"), alignment=TA_RIGHT))],
    ]
    detail_table = Table(detail_data, colWidths=[3*inch, 3*inch])
    detail_table.setStyle(TableStyle([
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 16),
        ("RIGHTPADDING", (0, 0), (-1, -1), 16),
        ("LINEBELOW", (0, 0), (-1, -2), 0.5, HexColor("#E2E8F0")),
    ]))
    elements.append(detail_table)

    elements.append(Spacer(1, 8))

    total_table = Table([
        [Paragraph("TOTAL PAGADO", total_label_style),
         Paragraph(f"${amount:,.2f} MXN", total_value_style)]
    ], colWidths=[3*inch, 3*inch])
    total_table.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.5, HexColor("#4F46E5")),
        ("TOPPADDING", (0, 0), (-1, -1), 12),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 12),
        ("LEFTPADDING", (0, 0), (-1, -1), 16),
        ("RIGHTPADDING", (0, 0), (-1, -1), 16),
        ("BACKGROUND", (0, 0), (-1, -1), HexColor("#F8F9FF")),
    ]))
    elements.append(total_table)

    elements.append(Spacer(1, 30))
    elements.append(Paragraph(
        "Gracias por tu preferencia. Forja Trabajo — © 2025",
        ParagraphStyle("Footer", parent=styles["Normal"],
                       fontSize=8, textColor=HexColor("#94A3B8"),
                       alignment=TA_CENTER)
    ))

    doc.build(elements)
    return tmp.name
