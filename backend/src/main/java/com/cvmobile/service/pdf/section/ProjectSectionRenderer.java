package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfRenderUtils;
import com.lowagie.text.Chunk;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;

import java.util.List;

public final class ProjectSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        List<CvResponse.ProjectDto> projects = context.cv().getProjects();
        if (projects == null || projects.isEmpty()) return;
        SectionTitleRenderer.render(context, "PROJETS");
        for (CvResponse.ProjectDto project : projects) {
            Paragraph title = new Paragraph();
            if (project.getNom() != null) title.add(new Chunk(project.getNom(), context.fonts().item()));
            context.add(title);
            if (project.getDescription() != null && !project.getDescription().isBlank()) {
                context.add(new Paragraph(project.getDescription(), context.fonts().body()));
            }
            String period = PdfRenderUtils.period(
                    project.getDateDebut() == null ? null
                            : project.getDateDebut().format(PdfRenderUtils.DATE_FORMAT),
                    project.getDateFin() == null ? null
                            : project.getDateFin().format(PdfRenderUtils.DATE_FORMAT));
            String details = PdfRenderUtils.joinNonBlank("  •  ",
                    project.getTechnologies(), period, project.getLien());
            if (details != null) {
                Paragraph paragraph = new Paragraph(details, context.fonts().sub());
                paragraph.setSpacingAfter(8);
                context.add(paragraph);
            }
        }
    }
}
