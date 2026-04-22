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
    public Map<String, String> generateResume(String titrePoste, String competences, String experience) {
        String prompt = "Tu es un expert en redaction de CV professionnels. "
                + "Ecris un resume professionnel percutant de 3-4 phrases pour un CV. "
                + "REGLES: "
                + "- Commence par le titre du poste et les annees d'experience "
                + "- Mentionne les competences cles "
                + "- Inclus un resultat chiffre si possible "
                + "- JAMAIS de mots cliches (motive, dynamique, passionne, rigoureux) "
                + "- Utilise des verbes d'action concrets "
                + "- Reponds UNIQUEMENT avec le texte du resume, rien d'autre\n\n"
                + "Poste: " + (titrePoste != null ? titrePoste : "non precise") + "\n"
                + "Competences: " + (competences != null ? competences : "non precisees") + "\n"
                + "Experience: " + (experience != null ? experience : "non precisee");

        // Exceptions IA propagees au GlobalExceptionHandler (plus de fallback silencieux)
        String result = aiClient.complete(prompt, 500).strip();
        result = result.replaceAll("^\"|\"$", "");
        return Map.of("resume", result);
    }

    private String buildFallbackResume(String titrePoste) {
        if (titrePoste == null || titrePoste.isBlank()) {
            return "Professionnel experimente avec une expertise technique solide. "
                    + "Capable de concevoir et livrer des solutions adaptees aux besoins metier. "
                    + "A la recherche d'un nouveau defi pour apporter de la valeur a une equipe performante.";
        }
        return titrePoste + " avec une experience confirmee dans le domaine. "
                + "Expert dans la conception et la mise en oeuvre de solutions performantes. "
                + "Reconnu pour la qualite du travail livre et l'atteinte des objectifs fixes.";
    }
}
