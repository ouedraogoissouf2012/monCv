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

        var response = service.generateSuggestions("Developpeur", "Acme");

        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(aiClient).complete(prompt.capture(), org.mockito.ArgumentMatchers.eq(321));
        assertThat(prompt.getValue()).contains("exactement 3 bullet points");
        assertThat(response.getSuggestions()).containsExactly("Premier", "Deuxieme", "Troisieme");
    }
}
