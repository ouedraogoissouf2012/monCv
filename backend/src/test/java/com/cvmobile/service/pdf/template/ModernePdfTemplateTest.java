package com.cvmobile.service.pdf.template;

class ModernePdfTemplateTest extends AbstractPdfTemplateContractTest {
    @Override protected PdfTemplate template() { return new ModernePdfTemplate(); }
    @Override protected String goldenDigest() { return "39ea2aba67941bb21e5617748a3e0f1f59807307ece39b62b9d64ec9614a1b7b"; }
}
