package com.cvmobile.service.pdf.template;

import com.cvmobile.model.PdfTemplate;
import com.cvmobile.service.pdf.style.PdfTheme;

public final class ClassiquePdfTemplate extends AbstractPdfTemplate {

    @Override
    public PdfTemplate type() {
        return PdfTemplate.CLASSIQUE;
    }

    @Override
    protected PdfTheme theme() {
        return PdfTheme.classique();
    }
}
