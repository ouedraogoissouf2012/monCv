package com.cvmobile.service.pdf;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.PdfTemplate;

public interface PdfGenerationService {

    byte[] generateCvPdf(CvResponse cv, PdfTemplate template);
}
