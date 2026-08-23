package com.cvmobile.controller;

import com.cvmobile.dto.SuggestResponse;
import com.cvmobile.exception.GlobalExceptionHandler;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import com.cvmobile.service.ai.AiStatusService;
import com.cvmobile.service.ai.IApplicationMessageService;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.ai.IJobMatchService;
import com.cvmobile.service.ai.IResumeGeneratorService;
import com.cvmobile.service.ai.ISuggestionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.lang.reflect.Method;
import java.lang.reflect.Parameter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/// Verrouille la barriere de consentement RGPD des endpoints IA (issue #502)
/// au niveau HTTP, pour les CINQ endpoints.
///
/// Pourquoi ce test existe malgre `AiConsentValidationTest` : ce dernier
/// instancie un `Validator` et valide les DTO en isolation, il reste donc vert
/// meme si plus aucun controller n'applique la validation. `AiControllerTest`,
/// lui, appelle les methodes du controller en direct, hors contexte Spring MVC,
/// ou `@Valid` n'est jamais evalue.
///
/// Mesure sur `main` avant ce test : en retirant `@Valid` de
/// `AiController.suggest`, les 12 tests de consentement existants passaient
/// toujours (BUILD SUCCESS). La barriere pouvait donc etre supprimee sans
/// qu'aucun test ne le detecte.
///
/// Ce test ferme ce trou : il traverse la couche web reelle et verifie que
/// sans consentement la requete est rejetee en 400 ET qu'aucune donnee
/// utilisateur n'atteint un service appelant le fournisseur IA.
@ExtendWith(MockitoExtension.class)
class AiConsentWebGuardTest {

    @Mock private ISuggestionService suggestionService;
    @Mock private IResumeGeneratorService resumeGeneratorService;
    @Mock private IEnhancementService enhancementService;
    @Mock private IJobMatchService jobMatchService;
    @Mock private IApplicationMessageService applicationMessageService;
    @Mock private AiStatusService aiStatusService;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        AiController controller = new AiController(
                suggestionService, resumeGeneratorService, enhancementService,
                jobMatchService, applicationMessageService, aiStatusService);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    /// Corps valides au regard de TOUTES les autres contraintes du DTO : le seul
    /// motif de rejet possible est l'absence de consentement. Sans cette
    /// precaution, un 400 provoque par un champ manquant ferait passer le test
    /// sans rien prouver.
    static Stream<Arguments> endpointsIa() {
        return Stream.of(
                Arguments.of("/api/ai/suggest",
                        "{\"poste\":\"Developpeur backend\"}"),
                Arguments.of("/api/ai/generate-resume",
                        "{\"titrePoste\":\"Developpeur backend\"}"),
                Arguments.of("/api/ai/enhance-cv",
                        "{\"cvId\":1,\"level\":\"MEDIUM\"}"),
                Arguments.of("/api/ai/match-job",
                        "{\"cvId\":1,\"jobDescription\":\"Une offre suffisamment longue.\"}"),
                Arguments.of("/api/ai/application-messages",
                        "{\"cvId\":1,\"jobDescription\":\"Une offre suffisamment longue.\"}"));
    }

    /// `aiConsentAccepted` est un `boolean` primitif : un champ absent et un
    /// champ explicitement `false` produisent la meme valeur et empruntent le
    /// meme chemin de validation. Un seul cas suffit donc a couvrir les deux ;
    /// en ajouter un second n'apporterait aucune couverture.
    @ParameterizedTest(name = "{0} sans consentement -> 400")
    @MethodSource("endpointsIa")
    void endpointIa_sansConsentement_rejeteEn400(String path, String corpsSansConsentement)
            throws Exception {
        mvc.perform(post(path)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpsSansConsentement))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.details.aiConsentAccepted")
                        .value(containsString("consentement IA")))
                // Le consentement doit etre la SEULE violation : sans cette
                // assertion, un corps invalide par ailleurs ferait passer le
                // test sans rien prouver de la barriere.
                .andExpect(jsonPath("$.details.length()").value(1));

        // Aucune donnee utilisateur ne doit atteindre un service qui appelle le
        // fournisseur IA : c'est l'objet meme de la barriere RGPD.
        verifyNoInteractions(suggestionService, resumeGeneratorService,
                enhancementService, jobMatchService, applicationMessageService);
    }

    /// Verifie la regle sur TOUS les endpoints, y compris ceux qui n'existent
    /// pas encore (issue #530).
    ///
    /// Les tests MockMvc ci-dessus prouvent le comportement HTTP reel, mais ne
    /// couvrent que les endpoints enumeres : un endpoint ajoute plus tard leur
    /// echappait, et c'est exactement l'oubli contre lequel ils existent.
    /// Mesure avant ce test : un sixieme `@PostMapping` sans `@Valid` laissait
    /// la suite au vert (BUILD SUCCESS).
    ///
    /// Ce controle ne s'appuie sur aucune liste : il interroge le controleur.
    @Test
    void toutEndpointIa_exigeValidationEtChampDeConsentement() {
        List<String> manquants = new ArrayList<>();

        for (Method methode : AiController.class.getDeclaredMethods()) {
            if (!methode.isAnnotationPresent(PostMapping.class)) continue;

            Parameter corps = corpsDeRequete(methode);
            if (corps == null) {
                manquants.add(methode.getName() + " : aucun @RequestBody");
                continue;
            }
            if (!corps.isAnnotationPresent(Valid.class)) {
                manquants.add(methode.getName()
                        + " : @RequestBody sans @Valid, la validation du DTO"
                        + " n'est jamais declenchee");
                continue;
            }
            if (!declareConsentementObligatoire(corps.getType())) {
                manquants.add(methode.getName() + " : le DTO "
                        + corps.getType().getSimpleName()
                        + " n'a pas de champ aiConsentAccepted annote @AssertTrue");
            }
        }

        assertThat(manquants)
                .as("Tout endpoint IA doit imposer le consentement RGPD avant"
                        + " de transmettre des donnees utilisateur au fournisseur."
                        + " Endpoints non conformes")
                .isEmpty();
    }

    private static Parameter corpsDeRequete(Method methode) {
        for (Parameter parametre : methode.getParameters()) {
            if (parametre.isAnnotationPresent(RequestBody.class)) return parametre;
        }
        return null;
    }

    private static boolean declareConsentementObligatoire(Class<?> dto) {
        try {
            return dto.getDeclaredField("aiConsentAccepted")
                    .isAnnotationPresent(AssertTrue.class);
        } catch (NoSuchFieldException absent) {
            return false;
        }
    }

    /// Garantit que l'enumeration `endpointsIa()` reste exhaustive : sans cela,
    /// un endpoint conforme mais absent de la liste ne serait jamais exerce au
    /// niveau HTTP, et les garanties fines (400, champ nomme, aucun service
    /// sollicite) ne vaudraient que pour une partie du controleur.
    @Test
    void lEnumerationCouvreTousLesEndpointsDuControleur() {
        long endpointsDeclares = Stream.of(AiController.class.getDeclaredMethods())
                .filter(m -> m.isAnnotationPresent(PostMapping.class))
                .count();

        assertThat(endpointsIa().count())
                .as("Un @PostMapping a ete ajoute a AiController sans etre ajoute"
                        + " a endpointsIa() : ses garanties HTTP ne sont pas testees")
                .isEqualTo(endpointsDeclares);
    }

    /// Contre-epreuve : le meme corps, consentement accorde, passe la validation
    /// et atteint le service. Sans elle, les tests ci-dessus resteraient verts
    /// meme si l'endpoint rejetait tout, quelle que soit la raison.
    @Test
    void suggest_avecConsentement_atteintLeService() throws Exception {
        when(suggestionService.generateSuggestions("Developpeur backend", null, null))
                .thenReturn(SuggestResponse.builder()
                        .suggestions(List.of("Concu des APIs REST"))
                        .aiGenerated(true)
                        .build());

        mvc.perform(post("/api/ai/suggest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"poste\":\"Developpeur backend\",\"aiConsentAccepted\":true}"))
                .andExpect(status().isOk());

        verify(suggestionService).generateSuggestions("Developpeur backend", null, null);
    }
}
