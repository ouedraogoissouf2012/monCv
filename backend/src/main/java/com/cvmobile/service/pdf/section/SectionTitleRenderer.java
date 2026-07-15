package com.cvmobile.service.pdf.section;

import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.style.PdfTheme;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;

final class SectionTitleRenderer {

    private SectionTitleRenderer() {
    }

    static void render(PdfRenderContext context, String title) throws DocumentException {
        if (context.theme().titleStyle() == PdfTheme.TitleStyle.BAND) {
            PdfPTable table = new PdfPTable(1);
            table.setWidthPercentage(100);
            table.setSpacingBefore(8);
            table.setSpacingAfter(6);
            PdfPCell cell = new PdfPCell(new Phrase(title, context.fonts().sectionOnPrimary()));
            cell.setBackgroundColor(context.theme().primary());
            cell.setPadding(5);
            cell.setBorder(Rectangle.NO_BORDER);
            table.addCell(cell);
            context.add(table);
            return;
        }
        if (context.theme().titleStyle() == PdfTheme.TitleStyle.RULE) {
            PdfPTable rule = new PdfPTable(1);
            rule.setWidthPercentage(100);
            rule.setSpacingBefore(10);
            rule.setSpacingAfter(4);
            PdfPCell cell = new PdfPCell();
            cell.setBorder(Rectangle.BOTTOM);
            cell.setBorderColor(context.theme().light());
            cell.setFixedHeight(0);
            rule.addCell(cell);
            context.add(rule);
        }
        Paragraph paragraph = new Paragraph(title, context.fonts().section());
        paragraph.setSpacingBefore(6);
        paragraph.setSpacingAfter(6);
        context.add(paragraph);
    }
}
