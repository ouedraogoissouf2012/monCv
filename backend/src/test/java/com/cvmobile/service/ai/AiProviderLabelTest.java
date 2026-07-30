package com.cvmobile.service.ai;

import com.cvmobile.service.ai.client.DeepSeekClient;
import com.cvmobile.service.ai.client.MockAiClient;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verrouille la non-divulgation du nom technique du fournisseur IA
 * (charte, issue #336).
 */
class AiProviderLabelTest {

    @Test
    void deepseekMappedToPrimary() {
        assertThat(AiProviderLabel.toPublicLabel(DeepSeekClient.PROVIDER_NAME))
                .isEqualTo(AiProviderLabel.PRIMARY);
    }

    @Test
    void mockMappedToFallback() {
        assertThat(AiProviderLabel.toPublicLabel(MockAiClient.PROVIDER_NAME))
                .isEqualTo(AiProviderLabel.FALLBACK);
    }

    @Test
    void insensibleALaCasse() {
        assertThat(AiProviderLabel.toPublicLabel("DeepSeek"))
                .isEqualTo(AiProviderLabel.PRIMARY);
        assertThat(AiProviderLabel.toPublicLabel("MOCK"))
                .isEqualTo(AiProviderLabel.FALLBACK);
    }

    @Test
    void providerInconnuMappedToUnknown() {
        assertThat(AiProviderLabel.toPublicLabel("openai"))
                .isEqualTo(AiProviderLabel.UNKNOWN);
    }

    @Test
    void nullMappedToUnknown() {
        assertThat(AiProviderLabel.toPublicLabel(null))
                .isEqualTo(AiProviderLabel.UNKNOWN);
    }

    @Test
    void aucun_libelle_public_ne_divulgue_le_nom_technique() {
        // Garde-fou : les libelles publics ne doivent jamais contenir un nom
        // technique de fournisseur.
        for (final String label : new String[] {
                AiProviderLabel.PRIMARY,
                AiProviderLabel.FALLBACK,
                AiProviderLabel.UNKNOWN,
        }) {
            assertThat(label.toLowerCase())
                    .doesNotContain(DeepSeekClient.PROVIDER_NAME)
                    .doesNotContain(MockAiClient.PROVIDER_NAME);
        }
    }
}
