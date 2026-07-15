package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.PdfTemplate;

/**
 * Backward-compatible facade used by controllers and existing integrations.
 */
@org.springframework.stereotype.Service
public class PdfGenerationService {

    private final com.cvmobile.service.pdf.PdfGenerationService delegate;

    public PdfGenerationService() {
        this(new com.cvmobile.service.pdf.PdfGenerationServiceImpl());
    }

    PdfGenerationService(com.cvmobile.service.pdf.PdfGenerationService delegate) {
        this.delegate = delegate;
    }

    public byte[] generateCvPdf(CvResponse cv, PdfTemplate template) {
        return delegate.generateCvPdf(cv, template);
    }
}
