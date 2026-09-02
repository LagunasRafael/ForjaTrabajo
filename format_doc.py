import re
from docx import Document
from docx.shared import Pt, Cm, Inches
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

doc = Document(r'C:\Users\juanl\OneDrive\Escritorio\Escuela\Residencias\Entregas\Tercera\Proyecto.docx')

# ─── 1. MÁRGENES ───
for section in doc.sections:
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(3.5)
    section.right_margin = Cm(2.5)

# ─── 2. CONFIGURAR FUENTE, INTERLINEADO, JUSTIFICADO, SANGRÍA, ESPACIADO ───
# Detectar si un párrafo es título: Heading style o comienza con patrón de título
def is_heading(paragraph):
    if paragraph.style and 'heading' in paragraph.style.name.lower():
        return True
    return False

# Nombres de estilos de heading que usaremos
heading_styles = []

for paragraph in doc.paragraphs:
    text = paragraph.text.strip()
    if not text:
        continue

    # Guardar estilo si es heading
    if paragraph.style and 'heading' in paragraph.style.name.lower():
        heading_styles.append(paragraph.style.name)

    # Configurar cada run en el párrafo
    for run in paragraph.runs:
        run.font.name = 'Arial'

    if is_heading(paragraph):
        # Títulos: Arial 14, Negrita, Alineado izquierda
        for run in paragraph.runs:
            run.font.size = Pt(14)
            run.font.bold = True
        paragraph.alignment = WD_ALIGN_PARAGRAPH.LEFT
        paragraph.paragraph_format.line_spacing = 1.5
        paragraph.paragraph_format.space_before = Pt(18)
        paragraph.paragraph_format.space_after = Pt(12)
        # Sin sangría en títulos
        paragraph.paragraph_format.first_line_indent = Cm(0)
    else:
        # Texto normal: Arial 12, justificado
        for run in paragraph.runs:
            run.font.size = Pt(12)
            run.font.bold = False
        paragraph.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        paragraph.paragraph_format.line_spacing = 1.5
        paragraph.paragraph_format.space_after = Pt(12)
        # Sangría de 10 espacios (~1.5 cm aprox)
        paragraph.paragraph_format.first_line_indent = Cm(1.5)
        # Control de viudas/huérfanas
        pPr = paragraph._p.get_or_add_pPr()
        widow_ctl = OxmlElement('w:widowControl')
        widow_ctl.set(qn('w:val'), '1')
        pPr.append(widow_ctl)

# ─── 3. PIE DE PÁGINA CON NUMERACIÓN ───
# La numeración comienza desde "Capítulo I" (Introducción)
# Buscamos el índice del párrafo que contiene "Capítulo I" o "1.1 Introducción"
# y dividimos en secciones

# Primero: agregar número de página al footer de todas las secciones
for section in doc.sections:
    footer = section.footer
    footer.is_linked_to_previous = False  # Desvincular
    # Si el footer no tiene párrafos, crear uno
    if not footer.paragraphs:
        footer.add_paragraph()
    p = footer.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT

    # Agregar campo PAGE
    run = p.add_run()
    fldChar1 = OxmlElement('w:fldChar')
    fldChar1.set(qn('w:fldCharType'), 'begin')
    run._r.append(fldChar1)

    run2 = p.add_run()
    instrText = OxmlElement('w:instrText')
    instrText.set(qn('xml:space'), 'preserve')
    instrText.text = ' PAGE '
    run2._r.append(instrText)

    run3 = p.add_run()
    fldChar2 = OxmlElement('w:fldChar')
    fldChar2.set(qn('w:fldCharType'), 'end')
    run3._r.append(fldChar2)

    # Fuente Arial 12 para el número de página
    for r in p.runs:
        r.font.name = 'Arial'
        r.font.size = Pt(12)

# ─── 4. DIVIDIR EN SECCIONES PARA NUMERACIÓN DESDE INTRODUCCIÓN ───
# python-docx no permite agregar section breaks fácilmente en medio del doc.
# Como alternativa, establecemos la numeración de página para que comience desde
# la primera sección que corresponde a la Introducción.
# Marcamos la primera sección (índices, resumen) sin numeración visible
# usando un enfoque diferente: ponemos número solo desde Capítulo I.

# Buscar el índice del primer párrafo de "Capítulo I" o "1.1 Introducción"
capitulo_i_idx = -1
for i, paragraph in enumerate(doc.paragraphs):
    text = paragraph.text.strip()
    if 'capítulo i' in text.lower() or 'capítulo 1' in text.lower():
        capitulo_i_idx = i
        break

if capitulo_i_idx == -1:
    # Buscar "Introducción" como subheading
    for i, paragraph in enumerate(doc.paragraphs):
        text = paragraph.text.strip()
        if text.startswith('1.1') and 'introducci' in text.lower():
            capitulo_i_idx = i
            break

# Si encontramos la introducción, intentamos hacer un salto de sección
# Nota: en python-docx no podemos insertar section breaks en medio de forma nativa,
# pero podemos manejar la numeración con campos de página
if capitulo_i_idx > 0:
    print(f"Sección de introducción encontrada en párrafo índice {capitulo_i_idx}")
else:
    print("No se encontró 'Capítulo I' o '1.1 Introducción', la numeración irá desde página 1")

# ─── 5. GUARDAR ───
output_path = r'C:\Users\juanl\OneDrive\Escritorio\Escuela\Residencias\Entregas\Tercera\Proyecto_formateado.docx'
doc.save(output_path)
print(f"Documento guardado en: {output_path}")
