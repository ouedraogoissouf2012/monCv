package com.cvmobile.service.pdf.section;

import com.cvmobile.service.pdf.PdfRenderContext;
import com.lowagie.text.DocumentException;

public interface PdfSectionRenderer {

    void render(PdfRenderContext context) throws DocumentException;
}
