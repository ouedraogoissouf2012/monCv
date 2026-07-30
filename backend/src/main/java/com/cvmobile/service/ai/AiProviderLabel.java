package com.cvmobile.service.ai;

import com.cvmobile.service.ai.client.DeepSeekClient;
import com.cvmobile.service.ai.client.MockAiClient;

/**
 * Traduit le nom technique d'un fournisseur IA en un libelle public neutre
 * (issue #336).
 *
 * <p>La charte du projet interdit d'exposer le nom du fournisseur IA
 * ("deepseek") aux utilisateurs. Toute valeur destinee au corps d'une reponse
 * HTTP ou a un DTO serialise DOIT passer par {@link #toPublicLabel(String)}.
 * Les logs serveur, eux, conservent le nom technique reel (non expose).</p>
 */
public final class AiProviderLabel {

    /** Fournisseur principal (masque "deepseek"). */
    public static final String PRIMARY = "primary";

    /** Fournisseur de repli (masque "mock"). */
    public static final String FALLBACK = "fallback";

    /** Fournisseur non reconnu : aucun detail divulgue. */
    public static final String UNKNOWN = "unknown";

    private AiProviderLabel() {
    }

    /**
     * Convertit un nom technique de provider en libelle public neutre.
     *
     * @param technicalName nom interne (ex. "deepseek", "mock"), potentiellement
     *                      null
     * @return "primary", "fallback" ou "unknown" — jamais le nom technique
     */
    public static String toPublicLabel(String technicalName) {
        if (technicalName == null) {
            return UNKNOWN;
        }
        if (DeepSeekClient.PROVIDER_NAME.equalsIgnoreCase(technicalName)) {
            return PRIMARY;
        }
        if (MockAiClient.PROVIDER_NAME.equalsIgnoreCase(technicalName)) {
            return FALLBACK;
        }
        return UNKNOWN;
    }
}
