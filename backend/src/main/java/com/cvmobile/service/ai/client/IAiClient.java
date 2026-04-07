package com.cvmobile.service.ai.client;

/**
 * Interface abstraite pour les appels IA.
 * Permet de changer de fournisseur (DeepSeek, Claude, GPT) sans modifier la logique metier.
 */
public interface IAiClient {

    /**
     * Envoie un prompt a l'IA et retourne la reponse brute.
     * @param prompt Le texte du prompt
     * @param maxTokens Nombre maximum de tokens en reponse
     * @return La reponse texte de l'IA
     */
    String complete(String prompt, int maxTokens);

    /**
     * Verifie si le client IA est configure (cle API presente).
     */
    boolean isAvailable();
}
