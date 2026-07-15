package com.cvmobile.service.pdf.template;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.PdfGenerationException;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.section.CertificationSectionRenderer;
import com.cvmobile.service.pdf.section.EducationSectionRenderer;
import com.cvmobile.service.pdf.section.ExperienceSectionRenderer;
import com.cvmobile.service.pdf.section.HeaderSectionRenderer;
import com.cvmobile.service.pdf.section.LanguageSectionRenderer;
import com.cvmobile.service.pdf.section.ProjectSectionRenderer;
import com.cvmobile.service.pdf.section.SkillSectionRenderer;
import com.cvmobile.service.pdf.section.SummarySectionRenderer;
import com.cvmobile.service.pdf.style.PdfFonts;
import com.cvmobile.service.pdf.style.PdfTheme;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.PageSize;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

public final class MinimalistePdfTemplate implements com.cvmobile.service.pdf.template.PdfTemplate {

    @Override
    public PdfTemplate type() {
        return PdfTemplate.MINIMALISTE;
    }

    @Override
    public byte[] render(CvResponse cv) {
        PdfTheme theme = PdfTheme.minimaliste();
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4, 0, 0, 0, 0);
            PdfWriter.getInstance(document, output);
            document.open();
            PdfPTable columns = new PdfPTable(new float[]{3f, 7f});
            columns.setWidthPercentage(100);
            columns.setExtendLastRow(true);
            PdfPCell sidebar = cell(theme.light(), 18);
            PdfPCell main = cell(theme.surface(), 24);
            PdfRenderContext base = new PdfRenderContext(cv, theme, new PdfFonts(theme), document::add);
            PdfRenderContext sidebarContext = base.withSink(sidebar::addElement);
            PdfRenderContext mainContext = base.withSink(main::addElement);
            new HeaderSectionRenderer().render(sidebarContext);
            new SkillSectionRenderer().render(sidebarContext);
            new LanguageSectionRenderer().render(sidebarContext);
            new SummarySectionRenderer().render(mainContext);
            new ExperienceSectionRenderer().render(mainContext);
            new EducationSectionRenderer().render(mainContext);
            new CertificationSectionRenderer().render(mainContext);
            new ProjectSectionRenderer().render(mainContext);
            columns.addCell(sidebar);
            columns.addCell(main);
            document.add(columns);
            document.close();
            return output.toByteArray();
        } catch (DocumentException | IOException exception) {
            throw failure(exception);
        } catch (RuntimeException exception) {
            if (exception instanceof PdfGenerationException pdfException) throw pdfException;
            throw failure(exception);
        }
    }

    private PdfPCell cell(java.awt.Color color, float padding) {
        PdfPCell cell = new PdfPCell();
        cell.setBackgroundColor(color);
        cell.setPadding(padding);
        cell.setBorder(Rectangle.NO_BORDER);
        return cell;
    }

    private PdfGenerationException failure(Throwable cause) {
        return new PdfGenerationException("Impossible de générer le PDF MINIMALISTE", cause);
    }
}
