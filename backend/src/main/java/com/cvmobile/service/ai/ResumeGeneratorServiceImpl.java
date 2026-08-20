package com.cvmobile.service.ai;

import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.quality.ICvQualityService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * Generation de resume professionnel par IA.
 * Produit un resume de 3-4 phrases a partir du poste, competences et experience.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ResumeGeneratorServiceImpl implements IResumeGeneratorService {

    private final IAiClient aiClient;
    private final ICvQualityService qualityService;

    @Override
    public Map<String, Object> generateResume(String titrePoste, String competences, String experience) {
        String prompt = "Tu es un expert en redaction de CV professionnels. "
                + "Ecris un resume professionnel de 3-4 phrases pour un CV francophone. "
                + "REGLES: "
                + AiPromptRules.GRAMMAR_RULE
                + AiPromptRules.FRANCOPHONE_MARKET_RULE
                + AiPromptRules.ANTI_CLICHES_RULE
                + AiPromptRules.GROUNDING_RULE
                + "- Commence par le titre du poste et les annees d'experience "
                + "- Mentionne les competences cles "
                + "- Inclus un resultat chiffre si possible "
                + "- Utilise des verbes d'action concrets "
                + "- Garde un ton naturel, sobre, credible pour PME, cabinets RH et recruteurs internationaux "
                + "- Reponds UNIQUEMENT avec le texte du resume, rien d'autre\n\n"
                + "Poste: " + (titrePoste != null ? titrePoste : "non precise") + "\n"
                + "Competences: " + (competences != null ? competences : "non precisees") + "\n"
                + "Experience: " + (experience != null ? experience : "non precisee");

        // Exceptions IA propagees au GlobalExceptionHandler (plus de fallback silencieux)
        String result = aiClient.complete(prompt, 500).strip();
        boolean fallback = aiClient.isFallbackResult();
        result = qualityService.clean(result.replaceAll("^\"|\"$", ""));
        return Map.of(
                "resume", result,
                "aiGenerated", !fallback,
                "fallback", fallback);
    }
}
