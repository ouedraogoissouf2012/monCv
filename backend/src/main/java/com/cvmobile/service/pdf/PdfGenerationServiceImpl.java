package com.cvmobile.service.pdf;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.PdfGenerationException;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.service.pdf.template.ClassiquePdfTemplate;
import com.cvmobile.service.pdf.template.CreatifPdfTemplate;
import com.cvmobile.service.pdf.template.MinimalistePdfTemplate;
import com.cvmobile.service.pdf.template.ModernePdfTemplate;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * Implementation du service de generation PDF, geree par le container Spring
 * (issue #255) : plus aucune instanciation manuelle {@code new ...Impl()} hors
 * container. Assemble les strategies de modele par type de template.
 */
@Service
public final class PdfGenerationServiceImpl implements PdfGenerationService {

    private final Map<PdfTemplate, com.cvmobile.service.pdf.template.PdfTemplate> templates;

    public PdfGenerationServiceImpl() {
        this(List.of(
                new ModernePdfTemplate(),
                new ClassiquePdfTemplate(),
                new MinimalistePdfTemplate(),
                new CreatifPdfTemplate()));
    }

    PdfGenerationServiceImpl(List<com.cvmobile.service.pdf.template.PdfTemplate> strategies) {
        templates = new EnumMap<>(PdfTemplate.class);
        strategies.forEach(strategy -> templates.put(strategy.type(), strategy));
    }

    @Override
    public byte[] generateCvPdf(CvResponse cv, PdfTemplate template) {
        if (cv == null) {
            throw new PdfGenerationException("Le CV à exporter est obligatoire");
        }
        PdfTemplate selected = template == null ? PdfTemplate.MODERNE : template;
        com.cvmobile.service.pdf.template.PdfTemplate strategy = templates.get(selected);
        if (strategy == null) {
            throw new PdfGenerationException("Template PDF non pris en charge : " + selected);
        }
        return strategy.render(cv);
    }
}
