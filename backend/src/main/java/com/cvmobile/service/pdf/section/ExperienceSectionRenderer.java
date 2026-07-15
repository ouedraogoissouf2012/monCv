package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfRenderUtils;
import com.lowagie.text.Chunk;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;

import java.util.List;

public final class ExperienceSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        List<CvResponse.ExperienceDto> experiences = context.cv().getExperiences();
        if (experiences == null || experiences.isEmpty()) return;
        SectionTitleRenderer.render(context, "EXPÉRIENCES PROFESSIONNELLES");
        for (CvResponse.ExperienceDto experience : experiences) {
            Paragraph title = new Paragraph();
            if (experience.getPoste() != null) {
                title.add(new Chunk(experience.getPoste(), context.fonts().item()));
            }
            if (experience.getEntreprise() != null) {
                title.add(new Chunk("  —  " + experience.getEntreprise(), context.fonts().body()));
            }
            context.add(title);
            String period = PdfRenderUtils.period(
                    experience.getDateDebut() == null ? null
                            : experience.getDateDebut().format(PdfRenderUtils.DATE_FORMAT),
                    Boolean.TRUE.equals(experience.getActuel()) ? "Présent"
                            : experience.getDateFin() == null ? null
                            : experience.getDateFin().format(PdfRenderUtils.DATE_FORMAT));
            String details = PdfRenderUtils.joinNonBlank("  |  ", period, experience.getLieu());
            if (details != null) context.add(new Paragraph(details, context.fonts().sub()));
            if (experience.getDescription() != null && !experience.getDescription().isBlank()) {
                Paragraph description = new Paragraph(experience.getDescription(), context.fonts().body());
                description.setIndentationLeft(8);
                description.setSpacingAfter(9);
                context.add(description);
            }
        }
    }
}
