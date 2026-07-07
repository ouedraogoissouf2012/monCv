package com.cvmobile.model;

import jakarta.persistence.Embeddable;
import lombok.*;

@Embeddable
@Getter
@Setter
@ToString
@EqualsAndHashCode
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonalInfo {

    private String nom;

    private String prenom;

    private String email;

    private String telephone;

    private String adresse;

    private String ville;

    private String codePostal;

    private String pays;

    private String photoUrl;

    private String linkedIn;

    private String portfolio;

    @jakarta.persistence.Column(length = 500)
    private String titrePoste;

    @jakarta.persistence.Column(columnDefinition = "TEXT")
    private String resumeProfessionnel;
}
