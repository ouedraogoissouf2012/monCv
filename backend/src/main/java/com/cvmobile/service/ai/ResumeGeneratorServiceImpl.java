package com.cvmobile.service.ai;

import com.cvmobile.service.ai.client.IAiClient;
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

    @Override
    public Map<String, Object> generateResume(String titrePoste, String competences, String experience) {
        String prompt = "Tu es un expert en redaction de CV professionnels. "
                + "Ecris un resume professionnel de 3-4 phrases pour un CV francophone. "
                + "REGLES: "
                + AiPromptRules.FRANCOPHONE_MARKET_RULE
                + AiPromptRules.ANTI_CLICHES_RULE
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
        result = result.replaceAll("^\"|\"$", "");
        return Map.of(
                "resume", result,
                "aiGenerated", !fallback,
                "fallback", fallback);
    }

    private String buildFallbackResume(String titrePoste) {
        if (titrePoste == null || titrePoste.isBlank()) {
            return "Professionnel avec une experience solide dans la gestion de missions operationnelles. "
                    + "Capable de structurer le travail, suivre les priorites et livrer des resultats utiles aux equipes metier. "
                    + "Recherche un poste ou contribuer a des projets mesurables dans un environnement exigeant.";
        }
        return titrePoste + " avec une experience confirmee dans la realisation de missions concretes. "
                + "Intervient sur la structuration, l'execution et le suivi des activites avec une attention forte a la qualite. "
                + "Souhaite contribuer a des projets utiles, mesurables et adaptes aux besoins du terrain.";
    }
}
