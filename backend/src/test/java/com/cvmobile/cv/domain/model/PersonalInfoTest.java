package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("PersonalInfo (value object domaine)")
class PersonalInfoTest {

    private PersonalInfo full() {
        return PersonalInfo.builder()
                .nom("Traore")
                .prenom("Alex")
                .email("i@example.com")
                .telephone("+226 70 00 00 00")
                .adresse("Rue 1")
                .ville("Ouagadougou")
                .codePostal("01 BP")
                .pays("Burkina Faso")
                .photoUrl("https://cdn/x.png")
                .linkedIn("https://linkedin.com/in/x")
                .portfolio("https://x.dev")
                .titrePoste("Developpeur Backend")
                .resumeProfessionnel("Concu des systemes fiables")
                .build();
    }

    @Test
    @DisplayName("construit un PersonalInfo complet via builder")
    void buildsFull() {
        PersonalInfo info = full();

        assertThat(info.nom()).isEqualTo("Traore");
        assertThat(info.prenom()).isEqualTo("Alex");
        assertThat(info.email()).isEqualTo("i@example.com");
        assertThat(info.titrePoste()).isEqualTo("Developpeur Backend");
        assertThat(info.resumeProfessionnel()).isEqualTo("Concu des systemes fiables");
    }

    @Test
    @DisplayName("un PersonalInfo entierement vide est autorise (edition partielle)")
    void allowsEmpty() {
        PersonalInfo info = PersonalInfo.builder().build();

        assertThat(info.nom()).isNull();
        assertThat(info.email()).isNull();
    }

    @Test
    @DisplayName("normalise les espaces et convertit les blancs en null")
    void normalisesText() {
        PersonalInfo info = PersonalInfo.builder()
                .nom("  Traore  ")
                .prenom("   ")
                .titrePoste("  Dev  ")
                .build();

        assertThat(info.nom()).isEqualTo("Traore");
        assertThat(info.prenom()).isNull();
        assertThat(info.titrePoste()).isEqualTo("Dev");
    }

    @Test
    @DisplayName("permet de deriver une copie avec un nouveau titre de poste")
    void withTitrePoste() {
        PersonalInfo info = full().withTitrePoste("Lead Backend");

        assertThat(info.titrePoste()).isEqualTo("Lead Backend");
        assertThat(info.nom()).isEqualTo("Traore");
    }

    @Test
    @DisplayName("permet de deriver une copie avec un nouveau resume")
    void withResume() {
        PersonalInfo info = full().withResumeProfessionnel("Nouveau resume");

        assertThat(info.resumeProfessionnel()).isEqualTo("Nouveau resume");
        assertThat(info.email()).isEqualTo("i@example.com");
    }

    @Test
    @DisplayName("egalite par valeur")
    void valueEquality() {
        assertThat(full()).isEqualTo(full()).hasSameHashCodeAs(full());
    }
}
