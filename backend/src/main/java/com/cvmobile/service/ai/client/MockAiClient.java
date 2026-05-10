package com.cvmobile.service.ai.client;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Provider IA mock, deterministique. Utilise uniquement comme FALLBACK
 * par CompositeAiClient quand le provider principal (DeepSeek) est down.
 *
 * NE remplace PAS un provider absent : si DeepSeek retourne 401 (cle invalide),
 * CompositeAiClient laisse propager l'exception au lieu de fallback vers Mock
 * (pour ne pas masquer le probleme de config).
 *
 * Les reponses respectent le format de markers attendu par AiResponseParser
 * (TITRE_POSTE:, RESUME:, etc.) pour que les services IA parsent correctement.
 */
@Component("mockAiClient")
@ConditionalOnProperty(prefix = "ai.fallback", name = "enabled", havingValue = "true", matchIfMissing = true)
public class MockAiClient implements IAiClient {

    public static final String PROVIDER_NAME = "mock";

    @Override
    public boolean isAvailable() {
        return true;
    }

    @Override
    public String complete(String prompt, int maxTokens) {
        // Detection du type d'operation par les markers du prompt
        if (prompt.contains("SCORE:") || prompt.contains("MOTS_CLES_PRESENTS:")) {
            return mockJobMatchResponse();
        }
        if (prompt.contains("TITRE_POSTE:") && prompt.contains("RESUME:")) {
            return mockEnhanceResponse(prompt);
        }
        if (prompt.contains("5 bullet points") || prompt.contains("suggestions")) {
            return mockSuggestionsResponse();
        }
        return mockResumeResponse();
    }

    private String mockEnhanceResponse(String prompt) {
        return """
                TITRE_POSTE:
                Developpeur Senior

                RESUME:
                Professionnel experimente avec une expertise solide. Capable de concevoir et livrer des solutions adaptees aux besoins metier.
                """;
    }

    private String mockJobMatchResponse() {
        return """
                SCORE: 65

                MOTS_CLES_PRESENTS:
                - developpement
                - equipe

                MOTS_CLES_MANQUANTS:
                - kubernetes
                - terraform

                SUGGESTIONS:
                - Ajoutez des mots-cles techniques specifiques
                - Mentionnez vos resultats chiffres
                - Adaptez votre titre au poste vise

                RESUME_OPTIMISE:
                Resume professionnel adapte a l'offre d'emploi.
                """;
    }

    private String mockSuggestionsResponse() {
        return """
                Contribue activement a l'atteinte des objectifs d'equipe
                Ameliore les processus internes avec une reduction mesurable des delais
                Collabore avec les parties prenantes pour garantir la satisfaction client
                Gere plusieurs projets en parallele dans le respect des delais
                Propose des solutions innovantes avec un impact operationnel positif
                """;
    }

    private String mockResumeResponse() {
        return "Professionnel experimente dans son domaine, capable de concevoir et livrer "
                + "des solutions adaptees aux besoins metier. Reconnu pour la qualite du travail "
                + "et l'atteinte des objectifs.";
    }
}
