package com.cvmobile.service.ai;

import com.cvmobile.dto.SuggestResponse;
import com.cvmobile.service.ai.client.IAiClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Generation de suggestions de bullet points pour les experiences.
 * Produit 5 bullet points professionnels adaptes au poste.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SuggestionServiceImpl implements ISuggestionService {

    private final IAiClient aiClient;

    @Override
    public SuggestResponse generateSuggestions(String poste, String entreprise) {
        if (aiClient.isAvailable()) {
            try {
                String prompt = buildSuggestPrompt(poste, entreprise);
                String rawContent = aiClient.complete(prompt, 600);
                List<String> suggestions = AiResponseParser.parseSuggestions(rawContent);
                return SuggestResponse.builder()
                        .suggestions(suggestions)
                        .aiGenerated(true)
                        .build();
            } catch (Exception e) {
                log.warn("Suggestion generation failed, falling back to mock: {}", e.getMessage());
            }
        }
        return SuggestResponse.builder()
                .suggestions(generateMockSuggestions(poste))
                .aiGenerated(false)
                .build();
    }

    private String buildSuggestPrompt(String poste, String entreprise) {
        String context = entreprise != null && !entreprise.isBlank()
                ? " chez " + entreprise
                : "";
        return "Génère exactement 5 bullet points professionnels en français pour un CV. "
                + "Poste : " + poste + context + ". "
                + "Chaque bullet doit commencer par un verbe d'action au passé composé "
                + "et inclure un résultat mesurable. "
                + "Réponds uniquement avec les 5 points, un par ligne, sans numérotation ni tiret.";
    }

    private List<String> generateMockSuggestions(String poste) {
        String lc = poste == null ? "" : poste.toLowerCase();

        if (containsAny(lc, "développeur", "developer", "ingénieur", "engineer", "software", "tech")) {
            return List.of(
                    "Développé et livré des fonctionnalités clés réduisant le temps de réponse de 30%",
                    "Collaboré au sein d'une équipe agile pour tenir les délais de sprint à 95%",
                    "Amélioré la couverture de tests de 20%, réduisant les régressions en production",
                    "Conçu et documenté des APIs RESTful consommées par 3 applications métier",
                    "Résolu des bugs critiques en production dans un délai moyen de 2 heures"
            );
        }
        if (containsAny(lc, "manager", "chef", "lead", "directeur", "responsable")) {
            return List.of(
                    "Dirigé une équipe pluridisciplinaire avec un taux de satisfaction de 95%",
                    "Piloté la livraison de 5 projets stratégiques dans le respect des budgets",
                    "Mis en place une méthodologie agile réduisant les délais de livraison de 25%",
                    "Accompagné 3 collaborateurs vers une promotion interne en 12 mois",
                    "Contribué à la croissance du chiffre d'affaires de 18% sur l'exercice"
            );
        }
        return List.of(
                "Contribué activement à l'atteinte des objectifs d'équipe en dépassant les KPIs fixés",
                "Amélioré les processus internes en réduisant les délais de traitement de 20%",
                "Collaboré avec des parties prenantes internes et externes pour garantir la satisfaction client",
                "Géré plusieurs projets en parallèle dans le respect des délais et des budgets",
                "Proposé et implémenté des solutions innovantes ayant réduit les coûts opérationnels"
        );
    }

    private boolean containsAny(String text, String... keywords) {
        for (String kw : keywords) {
            if (text.contains(kw)) return true;
        }
        return false;
    }
}
