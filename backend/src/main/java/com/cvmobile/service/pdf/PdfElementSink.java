package com.cvmobile.service.pdf;

import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;

@FunctionalInterface
public interface PdfElementSink {

    void add(Element element) throws DocumentException;
}
