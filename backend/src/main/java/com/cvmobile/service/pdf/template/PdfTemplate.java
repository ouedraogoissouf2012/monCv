package com.cvmobile.service.pdf.template;

import com.cvmobile.dto.CvResponse;

public interface PdfTemplate {

    com.cvmobile.model.PdfTemplate type();

    byte[] render(CvResponse cv);
}
