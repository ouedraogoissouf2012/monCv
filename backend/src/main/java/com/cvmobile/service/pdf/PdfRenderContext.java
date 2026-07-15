package com.cvmobile.service.pdf;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.style.PdfFonts;
import com.cvmobile.service.pdf.style.PdfTheme;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;

public record PdfRenderContext(
        CvResponse cv,
        PdfTheme theme,
        PdfFonts fonts,
        PdfElementSink sink) {

    public void add(Element element) throws DocumentException {
        sink.add(element);
    }

    public PdfRenderContext withSink(PdfElementSink newSink) {
        return new PdfRenderContext(cv, theme, fonts, newSink);
    }
}
