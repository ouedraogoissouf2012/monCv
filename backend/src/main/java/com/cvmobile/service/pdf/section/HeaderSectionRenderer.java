package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfRenderUtils;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Paragraph;

public final class HeaderSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        CvResponse.PersonalInfoDto info = context.cv().getPersonalInfo();
        int alignment = context.theme().centeredHeader() ? Element.ALIGN_CENTER : Element.ALIGN_LEFT;
        String fullName = PdfRenderUtils.fullName(info);
        if (!fullName.isBlank()) {
            Paragraph name = new Paragraph(fullName, context.fonts().name());
            name.setAlignment(alignment);
            name.setSpacingAfter(4);
            context.add(name);
        }
        if (info == null) return;
        if (info.getTitrePoste() != null && !info.getTitrePoste().isBlank()) {
            Paragraph job = new Paragraph(PdfRenderUtils.clean(info.getTitrePoste()), context.fonts().job());
            job.setAlignment(alignment);
            job.setSpacingAfter(8);
            context.add(job);
        }
        Paragraph contact = new Paragraph();
        contact.setAlignment(alignment);
        PdfRenderUtils.appendContact(contact, info.getEmail(), context.fonts().contact());
        PdfRenderUtils.appendContact(contact, info.getTelephone(), context.fonts().contact());
        PdfRenderUtils.appendContact(contact, PdfRenderUtils.location(info), context.fonts().contact());
        PdfRenderUtils.appendContact(contact, info.getLinkedIn(), context.fonts().contact());
        PdfRenderUtils.appendContact(contact, info.getPortfolio(), context.fonts().contact());
        contact.setSpacingAfter(12);
        context.add(contact);
    }
}
