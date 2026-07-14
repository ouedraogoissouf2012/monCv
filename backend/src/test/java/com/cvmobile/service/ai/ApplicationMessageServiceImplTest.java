package com.cvmobile.service.ai;

import com.cvmobile.dto.ApplicationMessagesResponse;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Skill;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ApplicationMessageServiceImplTest {

    @Mock
    private IAiClient aiClient;

    @Mock
    private CvRepository cvRepository;

    @InjectMocks
    private ApplicationMessageServiceImpl service;

    @BeforeEach
    void setUp() {
        Cv cv = Cv.builder()
                .id(42L)
                .personalInfo(PersonalInfo.builder()
                        .prenom("Awa")
                        .nom("Traore")
                        .titrePoste("Cheffe de projet digital")
                        .resumeProfessionnel("Pilotage de projets web pour des PME")
                        .build())
                .skills(List.of(Skill.builder().nom("Gestion de projet").build()))
                .experiences(List.of(Experience.builder()
                        .poste("Cheffe de projet")
                        .entreprise("Acme")
                        .description("Livre 8 projets dans les delais")
                        .build()))
                .build();
        when(cvRepository.findByIdWithDetails(42L)).thenReturn(Optional.of(cv));
    }

    @Test
    void generate_parseLesQuatreFormatsEtNettoieLeMarkdown() {
        when(aiClient.complete(anyString(), anyInt())).thenReturn("""
                LETTRE_MOTIVATION:
                **Madame, Monsieur,**
                Mon experience en gestion de projet repond a votre besoin.

                EMAIL_CANDIDATURE:
                Objet : Candidature Cheffe de projet
                Je vous adresse ma candidature.

                MESSAGE_LINKEDIN:
                Bonjour, votre offre de Cheffe de projet correspond a mon parcours.

                MESSAGE_WHATSAPP:
                Bonjour, je vous transmets ma candidature pour le poste de Cheffe de projet.
                """);

        ApplicationMessagesResponse response = service.generate(
                42L, "Recherche Cheffe de projet digital pour piloter des projets web.", "DIRECT");

        assertThat(response.getCoverLetter()).doesNotContain("**");
        assertThat(response.getEmail()).startsWith("Objet :");
        assertThat(response.getLinkedIn()).contains("votre offre");
        assertThat(response.getWhatsApp()).contains("candidature");
        assertThat(response.getTone()).isEqualTo("DIRECT");
        assertThat(response.isAiGenerated()).isTrue();

        ArgumentCaptor<String> prompt = ArgumentCaptor.forClass(String.class);
        verify(aiClient).complete(prompt.capture(), anyInt());
        assertThat(prompt.getValue())
                .contains("Awa Traore", "Gestion de projet", "8 projets", "Recherche Cheffe de projet");
    }

    @Test
    void generate_marqueLeFallback() {
        when(aiClient.complete(anyString(), anyInt())).thenReturn(validResponse());
        when(aiClient.isFallbackResult()).thenReturn(true);

        ApplicationMessagesResponse response = service.generate(
                42L, "Recherche Cheffe de projet digital pour piloter des projets web.", "PROFESSIONAL");

        assertThat(response.isFallback()).isTrue();
        assertThat(response.isAiGenerated()).isFalse();
    }

    @Test
    void generate_reponseIncompleteDeclencheUneErreurDeParsing() {
        when(aiClient.complete(anyString(), anyInt())).thenReturn("""
                LETTRE_MOTIVATION:
                Une lettre seulement.
                """);

        assertThatThrownBy(() -> service.generate(
                42L, "Recherche Cheffe de projet digital pour piloter des projets web.", "SIMPLE"))
                .isInstanceOf(AiParseException.class)
                .hasMessageContaining("messages de candidature");
    }

    @Test
    void generate_propageLesErreursDuFournisseur() {
        when(aiClient.complete(anyString(), anyInt()))
                .thenThrow(new IllegalStateException("Fournisseur indisponible"));

        assertThatThrownBy(() -> service.generate(
                42L, "Recherche Cheffe de projet digital pour piloter des projets web.", "SENIOR"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Fournisseur indisponible");
    }

    private String validResponse() {
        return """
                LETTRE_MOTIVATION:
                Lettre complete.
                EMAIL_CANDIDATURE:
                Email complet.
                MESSAGE_LINKEDIN:
                Message LinkedIn complet.
                MESSAGE_WHATSAPP:
                Message WhatsApp complet.
                """;
    }
}
