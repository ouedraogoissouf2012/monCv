package com.cvmobile.service.pdf.template;

import com.cvmobile.model.PdfTemplate;
import com.cvmobile.service.pdf.style.PdfTheme;

public final class CreatifPdfTemplate extends AbstractPdfTemplate {

    @Override
    public PdfTemplate type() {
        return PdfTemplate.CREATIF;
    }

    @Override
    protected PdfTheme theme() {
        return PdfTheme.creatif();
    }
}
