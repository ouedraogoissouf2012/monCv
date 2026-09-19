package com.cvmobile.architecture;

import static org.assertj.core.api.Assertions.assertThat;

import com.cvmobile.model.User;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Garde-fou des champs a mutation controlee (issue #535).
 *
 * <p>Certains champs portent un invariant de securite que seule une methode
 * metier sait respecter. Un setter genere par Lombok court-circuiterait cet
 * invariant sans qu'aucun test ne le signale : {@code tokenVersion} en est le
 * cas fondateur, un {@code setTokenVersion(0)} reactivant tous les jetons
 * precedemment revoques.
 *
 * <p>La suppression du setter est garantie par le compilateur
 * ({@code @Setter(AccessLevel.NONE)}). Ce garde-fou existe pour que retirer
 * cette annotation redevienne un echec de build plutot qu'une regression
 * silencieuse.
 *
 * <p>Ouvert a l'extension : proteger un nouveau champ se fait en ajoutant une
 * ligne a {@link #CHAMPS_PROTEGES}, sans toucher aux assertions.
 */
@DisplayName("Les champs a mutation controlee n'exposent aucun setter")
class ControlledMutationGuardTest {

    /**
     * Champ dont la mutation n'est permise qu'a travers une methode metier.
     *
     * @param porteur          la classe qui declare le champ
     * @param champ            le nom du champ protege
     * @param mutateurAutorise la seule methode habilitee a le modifier
     */
    private record ChampProtege(Class<?> porteur, String champ, String mutateurAutorise) {

        /** Nom du setter que Lombok genererait pour ce champ. */
        String setterInterdit() {
            return "set" + Character.toUpperCase(champ.charAt(0)) + champ.substring(1);
        }
    }

    private static final List<ChampProtege> CHAMPS_PROTEGES = List.of(
            new ChampProtege(User.class, "tokenVersion", "revokeSessions"));

    @Test
    @DisplayName("aucun setter n'est expose pour un champ protege")
    void aucunSetterNEstExposePourUnChampProtege() {
        for (ChampProtege protege : CHAMPS_PROTEGES) {
            List<String> setters = Arrays.stream(protege.porteur().getMethods())
                    .map(Method::getName)
                    .filter(nom -> nom.equals(protege.setterInterdit()))
                    .toList();

            assertThat(setters)
                    .as("%s.%s() contournerait l'invariant porte par %s.%s() : "
                                    + "verifier que @Setter(AccessLevel.NONE) est toujours "
                                    + "present sur le champ",
                            protege.porteur().getSimpleName(), protege.setterInterdit(),
                            protege.porteur().getSimpleName(), protege.mutateurAutorise())
                    .isEmpty();
        }
    }

    @Test
    @DisplayName("le mutateur autorise existe encore")
    void leMutateurAutoriseExisteEncore() {
        for (ChampProtege protege : CHAMPS_PROTEGES) {
            List<String> mutateurs = Arrays.stream(protege.porteur().getDeclaredMethods())
                    .map(Method::getName)
                    .filter(nom -> nom.equals(protege.mutateurAutorise()))
                    .toList();

            assertThat(mutateurs)
                    .as("%s.%s() a disparu : le garde-fou protegerait un champ que plus "
                                    + "aucune methode ne sait muter correctement",
                            protege.porteur().getSimpleName(), protege.mutateurAutorise())
                    .isNotEmpty();
        }
    }

    @Test
    @DisplayName("le champ protege reste prive")
    void leChampProtegeRestePrive() {
        for (ChampProtege protege : CHAMPS_PROTEGES) {
            assertThat(champEstPrive(protege))
                    .as("%s.%s doit rester prive : un champ package-private ou public "
                                    + "serait mutable sans passer par %s()",
                            protege.porteur().getSimpleName(), protege.champ(),
                            protege.mutateurAutorise())
                    .isTrue();
        }
    }

    /**
     * Vrai uniquement si le champ existe <em>et</em> est prive : un
     * {@code allMatch} sur un flux vide renverrait vrai pour un champ renomme,
     * laissant le garde-fou passer sur une cible disparue.
     */
    private static boolean champEstPrive(ChampProtege protege) {
        return Arrays.stream(protege.porteur().getDeclaredFields())
                .filter(field -> field.getName().equals(protege.champ()))
                .anyMatch(field -> Modifier.isPrivate(field.getModifiers()));
    }
}
