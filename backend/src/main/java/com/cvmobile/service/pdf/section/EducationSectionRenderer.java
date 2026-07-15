package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfRenderUtils;
import com.lowagie.text.Chunk;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;

import java.util.List;

public final class EducationSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        List<CvResponse.EducationDto> educations = context.cv().getEducations();
        if (educations == null || educations.isEmpty()) return;
        SectionTitleRenderer.render(context, "FORMATIONS");
        for (CvResponse.EducationDto education : educations) {
            Paragraph title = new Paragraph();
            if (education.getDiplome() != null) {
                title.add(new Chunk(education.getDiplome(), context.fonts().item()));
            }
            if (education.getEtablissement() != null) {
                title.add(new Chunk("  —  " + education.getEtablissement(), context.fonts().body()));
            }
            context.add(title);
            String period = PdfRenderUtils.period(
                    education.getDateDebut() == null ? null
                            : education.getDateDebut().format(PdfRenderUtils.DATE_FORMAT),
                    education.getDateFin() == null ? null
                            : education.getDateFin().format(PdfRenderUtils.DATE_FORMAT));
            String details = PdfRenderUtils.joinNonBlank("  •  ", education.getDomaine(), period);
            if (details != null) context.add(new Paragraph(details, context.fonts().sub()));
            if (education.getDescription() != null && !education.getDescription().isBlank()) {
                Paragraph description = new Paragraph(education.getDescription(), context.fonts().body());
                description.setIndentationLeft(8);
                description.setSpacingAfter(9);
                context.add(description);
            }
        }
    }
}
