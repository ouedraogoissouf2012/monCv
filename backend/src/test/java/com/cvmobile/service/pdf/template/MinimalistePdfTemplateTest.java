package com.cvmobile.service.pdf.template;

class MinimalistePdfTemplateTest extends AbstractPdfTemplateContractTest {
    @Override protected PdfTemplate template() { return new MinimalistePdfTemplate(); }
    @Override protected String goldenDigest() { return "7a785e4924a7dc77cda4a9c54598005e6ca1e2456a7049b2b8b906432dce0719"; }
}
