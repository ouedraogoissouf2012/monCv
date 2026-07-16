package com.cvmobile.service.ai;

import com.cvmobile.config.AiSuggestionProperties;
import com.cvmobile.service.ai.client.IAiClient;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class SuggestionServiceImplTest {

    @Test
    void appliesConfiguredPromptLimitAndCompletionTokens() {
        IAiClient aiClient = mock(IAiClient.class);
        SuggestionServiceImpl service = new SuggestionServiceImpl(
                aiClient,
                new AiSuggestionProperties(3, 321)
        );
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("Premier\nDeuxieme\nTroisieme\nQuatrieme");

        var response = service.generateSuggestions(
                "Agent de formation continue", "Acme", "Accompagnement des apprenants");

        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(aiClient).complete(prompt.capture(), org.mockito.ArgumentMatchers.eq(321));
        assertThat(prompt.getValue())
                .contains("exactement 3 propositions")
                .contains("Agent de formation continue")
                .contains("<DESCRIPTION>\nAccompagnement des apprenants\n</DESCRIPTION>")
                .contains("N'invente aucun outil, diplôme, mission, résultat, chiffre ou pourcentage")
                .contains("Ne change jamais de métier");
        assertThat(response.getSuggestions()).containsExactly("Premier", "Deuxieme", "Troisieme");
    }
}
