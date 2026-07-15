package com.cvmobile.service.pdf.template;

class ClassiquePdfTemplateTest extends AbstractPdfTemplateContractTest {
    @Override protected PdfTemplate template() { return new ClassiquePdfTemplate(); }
    @Override protected String goldenDigest() { return "286c91c84b36ba6124aa2a88feab507b44aa8bf39be27c22bc9ea4f1183fb72c"; }
}
