package com.cvmobile.service;

import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTPageMar;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTPageSz;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTSectPr;

import java.math.BigInteger;

final class DocxPageConfigurator {

    private DocxPageConfigurator() {
    }

    static void configureA4(XWPFDocument doc) {
        CTSectPr section = doc.getDocument().getBody().addNewSectPr();
        CTPageSz pageSize = section.addNewPgSz();
        pageSize.setW(BigInteger.valueOf(11_906));
        pageSize.setH(BigInteger.valueOf(16_838));
        CTPageMar margins = section.addNewPgMar();
        BigInteger margin = BigInteger.valueOf(1_134);
        margins.setTop(margin);
        margins.setRight(margin);
        margins.setBottom(margin);
        margins.setLeft(margin);
        margins.setHeader(BigInteger.valueOf(708));
        margins.setFooter(BigInteger.valueOf(708));
        margins.setGutter(BigInteger.ZERO);
    }
}
