package com.cvmobile.service.ai.client;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class IAiClientTest {

    /// Implementation minimale qui NE surcharge PAS isFallbackResult : exerce le
    /// comportement par defaut de l'interface.
    private static final class BareClient implements IAiClient {
        @Override
        public String complete(String prompt, int maxTokens) {
            return "reponse";
        }
    }

    @Test
    void isFallbackResult_parDefaut_estFalse() {
        // Contrat : le repli est opt-in ; un client qui ne le declare pas n'est
        // jamais considere comme un resultat de secours.
        assertThat(new BareClient().isFallbackResult()).isFalse();
    }
}
