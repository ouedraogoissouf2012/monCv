package com.cvmobile.service;

import com.cvmobile.model.Cv;
import com.cvmobile.service.quality.CvReviewAnalyzer;
import com.cvmobile.service.quality.CvTextCleaner;
import com.cvmobile.service.quality.ICvQualityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Facade de controle qualite du contenu CV genere par l'IA (issue #253).
 *
 * Delegue le nettoyage textuel a {@link CvTextCleaner} et la revue du CV a
 * {@link CvReviewAnalyzer}. Ne porte plus aucune logique : point d'entree stable
 * du contrat {@link ICvQualityService}.
 */
@Service
@RequiredArgsConstructor
public class CvQualityService implements ICvQualityService {

    private final CvTextCleaner textCleaner;
    private final CvReviewAnalyzer reviewAnalyzer;

    @Override
    public String clean(String text) {
        return textCleaner.clean(text);
    }

    @Override
    public String cleanProfessionalTerm(String text) {
        return textCleaner.cleanProfessionalTerm(text);
    }

    @Override
    public String removeRepeatedTitle(String description, String poste, String entreprise) {
        return textCleaner.removeRepeatedTitle(description, poste, entreprise);
    }

    @Override
    public List<String> findReviewWarnings(Cv cv) {
        return reviewAnalyzer.findReviewWarnings(cv);
    }
}
