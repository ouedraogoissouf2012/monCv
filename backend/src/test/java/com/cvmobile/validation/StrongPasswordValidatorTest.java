package com.cvmobile.validation;

import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.dto.ResetPasswordRequest;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Politique de mot de passe (issue #511).
 *
 * <p>Les assertions portent sur les DTO reels plutot que sur le validateur seul :
 * c'est l'application effective de la regle aux points d'entree qui compte. Un
 * test du validateur en isolation resterait vert si un DTO cessait de porter
 * l'annotation.
 */
class StrongPasswordValidatorTest {

    private final Validator validator =
            Validation.buildDefaultValidatorFactory().getValidator();

    private static final String VALIDE = "phrase de passe tranquille";

    @DisplayName("un mot de passe trop court est refuse a l'inscription")
    @ParameterizedTest(name = "\"{0}\" refuse")
    @ValueSource(strings = {"court", "12345678901", "abcdefghijk"})
    void inscription_motDePasseTropCourt_refuse(String trop_court) {
        RegisterRequest request = RegisterRequest.builder()
                .email("alex.traore@example.com")
                .password(trop_court)
                .nom("Traore").prenom("Alex")
                .build();

        assertThat(validator.validate(request))
                .as("moins de 12 caracteres doit etre rejete")
                .anyMatch(v -> v.getPropertyPath().toString().equals("password"));
    }

    @Test
    @DisplayName("l'ancien minimum de six caracteres n'est plus accepte")
    void inscription_ancienMinimumSixCaracteres_desormaisRefuse() {
        RegisterRequest request = RegisterRequest.builder()
                .email("alex.traore@example.com")
                .password("abc123")
                .nom("Traore").prenom("Alex")
                .build();

        assertThat(validator.validate(request))
                .as("la politique a ete durcie de 6 a 12 caracteres (#511)")
                .isNotEmpty();
    }

    @DisplayName("un mot de passe courant est refuse malgre sa longueur")
    @ParameterizedTest(name = "\"{0}\" refuse")
    @ValueSource(strings = {"azertyuiop123", "motdepasse123", "AZERTY123456"})
    void inscription_motDePasseCourant_refuse(String courant) {
        RegisterRequest request = RegisterRequest.builder()
                .email("alex.traore@example.com")
                .password(courant)
                .nom("Traore").prenom("Alex")
                .build();

        assertThat(validator.validate(request))
                .as("la longueur seule ne suffit pas : %s est dans les listes"
                        + " d'attaque, quelle que soit sa casse", courant)
                .anyMatch(v -> v.getMessage().contains("courant"));
    }

    @Test
    @DisplayName("une phrase de passe est acceptee sans exigence de composition")
    void inscription_phraseDePasse_acceptee() {
        RegisterRequest request = RegisterRequest.builder()
                .email("alex.traore@example.com")
                .password(VALIDE)
                .nom("Traore").prenom("Alex")
                .build();

        assertThat(validator.validate(request))
                .as("ni majuscule ni chiffre ne sont exiges : la longueur suffit")
                .isEmpty();
    }

    @Test
    @DisplayName("la reinitialisation applique exactement la meme politique")
    void reinitialisation_memePolitiqueQueInscription() {
        var faible = new ResetPasswordRequest("jeton-valide", "abc123");
        var solide = new ResetPasswordRequest("jeton-valide", VALIDE);

        assertThat(validator.validate(faible))
                .as("une reinitialisation ne doit pas etre une porte derobee"
                        + " vers un mot de passe faible")
                .isNotEmpty();
        assertThat(validator.validate(solide)).isEmpty();
    }

    @Test
    @DisplayName("un mot de passe absent releve de @NotBlank, pas de la politique")
    void motDePasseAbsent_unSeulMessage() {
        var sansMotDePasse = new ResetPasswordRequest("jeton-valide", null);

        assertThat(validator.validate(sansMotDePasse))
                .as("cumuler les deux regles produirait deux erreurs pour un champ vide")
                .hasSize(1);
    }
}
