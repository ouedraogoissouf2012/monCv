package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.lowagie.text.Chunk;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;

import java.util.List;

public final class SkillSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        List<CvResponse.SkillDto> skills = context.cv().getSkills();
        if (skills == null || skills.isEmpty()) return;
        SectionTitleRenderer.render(context, "COMPÉTENCES");
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setSpacingAfter(12);
        for (CvResponse.SkillDto skill : skills) {
            PdfPCell cell = new PdfPCell();
            cell.setBorder(Rectangle.NO_BORDER);
            cell.setPaddingBottom(5);
            Paragraph line = new Paragraph();
            if (skill.getNom() != null) line.add(new Chunk(skill.getNom(), context.fonts().body()));
            if (skill.getNiveau() != null) {
                int level = Math.max(0, Math.min(5, skill.getNiveau()));
                line.add(new Chunk("  " + level + "/5", context.fonts().sub()));
            }
            cell.addElement(line);
            table.addCell(cell);
        }
        if (skills.size() % 2 != 0) {
            PdfPCell empty = new PdfPCell();
            empty.setBorder(Rectangle.NO_BORDER);
            table.addCell(empty);
        }
        context.add(table);
    }
}
