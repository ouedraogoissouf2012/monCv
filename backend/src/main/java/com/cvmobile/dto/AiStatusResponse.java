package com.cvmobile.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * Etat agrege du sous-systeme IA expose via GET /api/ai/status.
 * Consommé cote Flutter par AiStatusProvider pour adapter l'UI
 * (boutons IA actifs ou desactives selon disponibilite).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AiStatusResponse {

    /** True si au moins un provider peut servir des requetes IA. */
    private boolean available;

    /** Nom du provider principal (ex: "deepseek"). */
    private String primaryProvider;

    /** Etat du provider principal : UP, DOWN, KEY_INVALID, RATE_LIMITED, CIRCUIT_OPEN, UNKNOWN. */
    private String primaryStatus;

    /** Etat Resilience4j exact : CLOSED, OPEN, HALF_OPEN, etc. */
    private String circuitBreakerState;

    /** Derniere erreur fournisseur connue. */
    private LastAiError lastError;

    private long latencyP50Ms;
    private long latencyP95Ms;
    private double errorRatePercent;
    private boolean fallbackInUse;

    /** True si un provider de fallback est configure et disponible. */
    private boolean fallbackAvailable;

    /** Nom du provider de fallback (ex: "mock") ou null. */
    private String fallbackProvider;

    /** Horodatage de la derniere mise a jour du status. */
    private Instant lastChecked;

    /** Alias contractuel du nouvel endpoint. */
    private Instant checkedAt;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LastAiError {
        private Instant timestamp;
        private String type;
    }
}
