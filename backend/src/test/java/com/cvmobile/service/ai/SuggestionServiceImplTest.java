package com.cvmobile.service.ai;

import com.cvmobile.config.AiSuggestionProperties;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.quality.CvReviewAnalyzer;
import com.cvmobile.service.quality.CvTextCleaner;
import com.cvmobile.service.quality.ICvQualityService;
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
                new AiSuggestionProperties(3, 321),
                quality()
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
                .contains("Ne change jamais de métier")
                .contains("SINGULIER MASCULIN");
        assertThat(response.getSuggestions()).containsExactly("Premier", "Deuxieme", "Troisieme");
    }

    @Test
    void entrepriseVideEtDescriptionNulle_utiliseLesReplisEtRefleteLeFallback() {
        IAiClient aiClient = mock(IAiClient.class);
        SuggestionServiceImpl service = new SuggestionServiceImpl(
                aiClient,
                new AiSuggestionProperties(2, 100),
                quality()
        );
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("Un\nDeux");
        when(aiClient.isFallbackResult()).thenReturn(true);

        var response = service.generateSuggestions("Vendeur", "   ", null);

        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(aiClient).complete(prompt.capture(), org.mockito.ArgumentMatchers.eq(100));
        assertThat(prompt.getValue())
                .doesNotContain(" chez ") // entreprise blanche -> aucun contexte entreprise
                .contains("(aucune description fournie)"); // description nulle -> repli
        // Un resultat de repli n'est jamais presente comme genere par l'IA.
        assertThat(response.isFallback()).isTrue();
        assertThat(response.isAiGenerated()).isFalse();
        assertThat(response.getSuggestions()).containsExactly("Un", "Deux");
    }

    @Test
    void nettoieMarkdownEtParticipesPluriels() {
        IAiClient aiClient = mock(IAiClient.class);
        SuggestionServiceImpl service = new SuggestionServiceImpl(
                aiClient, new AiSuggestionProperties(2, 100), quality());
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("Livrés **cinq** modules\nAnalyses les besoins");

        var response = service.generateSuggestions("Dev", "Acme", "Missions");

        assertThat(response.getSuggestions())
                .containsExactly("Livré cinq modules", "Analyse les besoins");
    }

    private static ICvQualityService quality() {
        return new CvQualityService(new CvTextCleaner(), mock(CvReviewAnalyzer.class));
    }
}
