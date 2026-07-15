package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.lowagie.text.Chunk;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Paragraph;

import java.util.List;

public final class LanguageSectionRenderer implements PdfSectionRenderer {

    @Override
    public void render(PdfRenderContext context) throws DocumentException {
        List<CvResponse.LanguageDto> languages = context.cv().getLanguages();
        if (languages == null || languages.isEmpty()) return;
        SectionTitleRenderer.render(context, "LANGUES");
        Paragraph line = new Paragraph();
        for (int index = 0; index < languages.size(); index++) {
            CvResponse.LanguageDto language = languages.get(index);
            String name = language.getLangue() == null ? "" : language.getLangue();
            String level = language.getNiveau() == null ? "" : " (" + language.getNiveau() + ")";
            if (index > 0) line.add(new Chunk("    ", context.fonts().body()));
            line.add(new Chunk(name + level, context.fonts().body()));
        }
        line.setSpacingAfter(12);
        context.add(line);
    }
}
