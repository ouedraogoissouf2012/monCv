package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfRenderUtils;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;

public final class SummarySectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        CvResponse.PersonalInfoDto info = context.cv().getPersonalInfo();
        if (info == null || info.getResumeProfessionnel() == null
                || info.getResumeProfessionnel().isBlank()) return;
        SectionTitleRenderer.render(context, "PROFIL");
        Paragraph summary = new Paragraph(
                PdfRenderUtils.clean(info.getResumeProfessionnel()), context.fonts().body());
        summary.setSpacingAfter(12);
        context.add(summary);
    }
}
