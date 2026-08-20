package com.cvmobile.service.ai.client;

import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.ai.ResumeGeneratorServiceImpl;
import com.cvmobile.service.quality.CvReviewAnalyzer;
import com.cvmobile.service.quality.CvTextCleaner;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class MockAiClientTest {

    private final MockAiClient client = new MockAiClient();

    @Test
    void marksDownstreamResponseAsFallbackAndNotAiGenerated() {
        ResumeGeneratorServiceImpl service = new ResumeGeneratorServiceImpl(
                client, new CvQualityService(new CvTextCleaner(), org.mockito.Mockito.mock(CvReviewAnalyzer.class)));

        Map<String, Object> response = service.generateResume(
                "Developpeur", "Java, Spring", "5 ans");

        assertThat(client.isFallbackResult()).isTrue();
        assertThat(response)
                .containsEntry("aiGenerated", false)
                .containsEntry("fallback", true);
    }

    @Test
    void returnsDeterministicResponseForSamePrompt() {
        String prompt = "Ecris un resume professionnel";

        String first = client.complete(prompt, 500);
        String second = client.complete(prompt, 500);

        assertThat(first).isEqualTo(second).isNotBlank();
    }

    @Test
    void selectsDeterministicTemplateFromPromptMarkers() {
        assertThat(client.complete("LETTRE_MOTIVATION: MESSAGE_WHATSAPP:", 500))
                .contains("EMAIL_CANDIDATURE:", "MESSAGE_LINKEDIN:");
        assertThat(client.complete("SCORE: MOTS_CLES_PRESENTS:", 500))
                .contains("SCORE: 65", "MOTS_CLES_MANQUANTS:");
        assertThat(client.complete("TITRE_POSTE: RESUME:", 500))
                .contains("Developpeur Senior");
        assertThat(client.complete("Donne 5 bullet points avec suggestions", 500))
                .contains("objectifs d'equipe");
    }

    @Test
    void hasNoNetworkCollaborator() {
        assertThat(Arrays.stream(MockAiClient.class.getDeclaredFields())
                .filter(field -> !Modifier.isStatic(field.getModifiers())))
                .isEmpty();
    }
}
