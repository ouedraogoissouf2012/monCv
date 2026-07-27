package com.cvmobile.cv.domain.model;

/**
 * Coordonnees et resume professionnel d'un CV (valeur de domaine immuable).
 *
 * <p>Comporte de nombreux champs, tous facultatifs (edition partielle). La
 * construction passe par un {@link Builder} ecrit a la main : le domaine ne
 * depend d'aucun generateur d'infrastructure (Lombok), et la normalisation des
 * chaines est appliquee de facon uniforme a la construction.
 *
 * @param nom                 nom de famille, ou {@code null}
 * @param prenom              prenom, ou {@code null}
 * @param email               adresse e-mail, ou {@code null}
 * @param telephone           numero de telephone, ou {@code null}
 * @param adresse             adresse postale, ou {@code null}
 * @param ville               ville, ou {@code null}
 * @param codePostal          code postal, ou {@code null}
 * @param pays                pays, ou {@code null}
 * @param photoUrl            URL de la photo, ou {@code null}
 * @param linkedIn            profil LinkedIn, ou {@code null}
 * @param portfolio           lien portfolio, ou {@code null}
 * @param titrePoste          titre du poste vise, ou {@code null}
 * @param resumeProfessionnel resume/accroche, ou {@code null}
 */
public record PersonalInfo(
        String nom,
        String prenom,
        String email,
        String telephone,
        String adresse,
        String ville,
        String codePostal,
        String pays,
        String photoUrl,
        String linkedIn,
        String portfolio,
        String titrePoste,
        String resumeProfessionnel) {

    /**
     * Compact constructor : normalise chaque champ (trim, blanc -> null) pour
     * garantir une representation canonique quel que soit le point d'entree.
     */
    public PersonalInfo {
        nom = DomainText.normalize(nom);
        prenom = DomainText.normalize(prenom);
        email = DomainText.normalize(email);
        telephone = DomainText.normalize(telephone);
        adresse = DomainText.normalize(adresse);
        ville = DomainText.normalize(ville);
        codePostal = DomainText.normalize(codePostal);
        pays = DomainText.normalize(pays);
        photoUrl = DomainText.normalize(photoUrl);
        linkedIn = DomainText.normalize(linkedIn);
        portfolio = DomainText.normalize(portfolio);
        titrePoste = DomainText.normalize(titrePoste);
        resumeProfessionnel = DomainText.normalize(resumeProfessionnel);
    }

    /** Cree un builder vide. */
    public static Builder builder() {
        return new Builder();
    }

    /** Derive une copie avec un nouveau titre de poste (adaptation IA). */
    public PersonalInfo withTitrePoste(String newTitrePoste) {
        return toBuilder().titrePoste(newTitrePoste).build();
    }

    /** Derive une copie avec un nouveau resume professionnel (adaptation IA). */
    public PersonalInfo withResumeProfessionnel(String newResume) {
        return toBuilder().resumeProfessionnel(newResume).build();
    }

    private Builder toBuilder() {
        return new Builder()
                .nom(nom).prenom(prenom).email(email).telephone(telephone)
                .adresse(adresse).ville(ville).codePostal(codePostal).pays(pays)
                .photoUrl(photoUrl).linkedIn(linkedIn).portfolio(portfolio)
                .titrePoste(titrePoste).resumeProfessionnel(resumeProfessionnel);
    }

    /** Builder fluide ecrit a la main (aucune dependance d'infrastructure). */
    public static final class Builder {
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
        private String titrePoste;
        private String resumeProfessionnel;

        private Builder() {
        }

        public Builder nom(String v) { this.nom = v; return this; }

        public Builder prenom(String v) { this.prenom = v; return this; }

        public Builder email(String v) { this.email = v; return this; }

        public Builder telephone(String v) { this.telephone = v; return this; }

        public Builder adresse(String v) { this.adresse = v; return this; }

        public Builder ville(String v) { this.ville = v; return this; }

        public Builder codePostal(String v) { this.codePostal = v; return this; }

        public Builder pays(String v) { this.pays = v; return this; }

        public Builder photoUrl(String v) { this.photoUrl = v; return this; }

        public Builder linkedIn(String v) { this.linkedIn = v; return this; }

        public Builder portfolio(String v) { this.portfolio = v; return this; }

        public Builder titrePoste(String v) { this.titrePoste = v; return this; }

        public Builder resumeProfessionnel(String v) { this.resumeProfessionnel = v; return this; }

        public PersonalInfo build() {
            return new PersonalInfo(
                    nom, prenom, email, telephone, adresse, ville, codePostal,
                    pays, photoUrl, linkedIn, portfolio, titrePoste,
                    resumeProfessionnel);
        }
    }
}
