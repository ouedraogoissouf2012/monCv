package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfRenderUtils;
import com.lowagie.text.Chunk;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;

import java.util.List;

public final class CertificationSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        List<CvResponse.CertificationDto> certifications = context.cv().getCertifications();
        if (certifications == null || certifications.isEmpty()) return;
        SectionTitleRenderer.render(context, "CERTIFICATIONS");
        for (CvResponse.CertificationDto certification : certifications) {
            Paragraph title = new Paragraph();
            if (certification.getNom() != null) {
                title.add(new Chunk(PdfRenderUtils.clean(certification.getNom()), context.fonts().item()));
            }
            if (certification.getOrganisme() != null) {
                title.add(new Chunk("  —  " + certification.getOrganisme(), context.fonts().body()));
            }
            context.add(title);
            String details = PdfRenderUtils.joinNonBlank("  •  ",
                    PdfRenderUtils.certificationPeriod(certification), certification.getCredentialUrl());
            if (details != null) {
                Paragraph paragraph = new Paragraph(details, context.fonts().sub());
                paragraph.setSpacingAfter(8);
                context.add(paragraph);
            }
        }
    }
}
