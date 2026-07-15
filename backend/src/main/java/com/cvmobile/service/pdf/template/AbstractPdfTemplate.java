package com.cvmobile.service.pdf.template;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.PdfGenerationException;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.section.CertificationSectionRenderer;
import com.cvmobile.service.pdf.section.EducationSectionRenderer;
import com.cvmobile.service.pdf.section.ExperienceSectionRenderer;
import com.cvmobile.service.pdf.section.HeaderSectionRenderer;
import com.cvmobile.service.pdf.section.LanguageSectionRenderer;
import com.cvmobile.service.pdf.section.PdfSectionRenderer;
import com.cvmobile.service.pdf.section.ProjectSectionRenderer;
import com.cvmobile.service.pdf.section.SkillSectionRenderer;
import com.cvmobile.service.pdf.section.SummarySectionRenderer;
import com.cvmobile.service.pdf.style.PdfFonts;
import com.cvmobile.service.pdf.style.PdfTheme;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.PageSize;
import com.lowagie.text.pdf.PdfWriter;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

abstract class AbstractPdfTemplate implements PdfTemplate {

    private static final List<PdfSectionRenderer> SECTIONS = List.of(
            new HeaderSectionRenderer(),
            new SummarySectionRenderer(),
            new ExperienceSectionRenderer(),
            new EducationSectionRenderer(),
            new SkillSectionRenderer(),
            new LanguageSectionRenderer(),
            new CertificationSectionRenderer(),
            new ProjectSectionRenderer());

    protected abstract PdfTheme theme();

    @Override
    public byte[] render(CvResponse cv) {
        PdfTheme theme = theme();
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4, theme.horizontalMargin(),
                    theme.horizontalMargin(), 40, 40);
            PdfWriter.getInstance(document, output);
            document.open();
            PdfRenderContext context = new PdfRenderContext(cv, theme, new PdfFonts(theme), document::add);
            for (PdfSectionRenderer section : SECTIONS) section.render(context);
            document.close();
            return output.toByteArray();
        } catch (DocumentException | IOException exception) {
            throw failure(exception);
        } catch (RuntimeException exception) {
            if (exception instanceof PdfGenerationException pdfException) throw pdfException;
            throw failure(exception);
        }
    }

    private PdfGenerationException failure(Throwable cause) {
        return new PdfGenerationException("Impossible de générer le PDF " + type().name(), cause);
    }
}
