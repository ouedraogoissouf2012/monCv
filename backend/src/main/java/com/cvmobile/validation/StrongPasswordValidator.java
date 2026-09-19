package com.cvmobile.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.util.Locale;
import java.util.Set;

/**
 * Applique la politique de {@link StrongPassword}.
 *
 * <p>Le validateur ne rejette jamais {@code null} : l'obligation de presence
 * releve de {@code @NotBlank}, porte separement par chaque DTO. Cumuler les deux
 * responsabilites produirait deux messages d'erreur pour un champ vide.
 */
public class StrongPasswordValidator
        implements ConstraintValidator<StrongPassword, String> {

    /**
     * Longueur minimale. Sans exigence de composition, c'est le seul facteur de
     * robustesse : 12 caracteres autorisent une phrase de passe memorisable tout
     * en rendant une attaque par force brute hors de portee.
     */
    static final int LONGUEUR_MINIMALE = 12;

    /** Borne haute : evite qu'un envoi volumineux ne sature le hachage BCrypt. */
    static final int LONGUEUR_MAXIMALE = 100;

    /**
     * Mots de passe les plus repandus, en francais et en anglais, plus les
     * suites de clavier. Comparaison insensible a la casse : {@code Azerty123456}
     * et {@code azerty123456} offrent la meme resistance, c'est-a-dire aucune.
     *
     * <p>Liste volontairement courte : elle arrete les choix les plus evidents
     * sans pretendre remplacer une base de mots de passe compromis, qui releve
     * d'un service externe.
     */
    private static final Set<String> MOTS_DE_PASSE_COURANTS = Set.of(
            "azertyuiop12", "azertyuiop123", "motdepasse12", "motdepasse123",
            "motdepasse1234", "123456789012", "1234567890123", "qwertyuiop12",
            "qwertyuiop123", "password1234", "passwordpassword", "administrateur",
            "jesuislemeilleur", "bonjourbonjour", "azerty123456", "qwerty123456",
            "iloveyou1234", "welcome12345", "monmotdepasse", "changemeplease",
            "loginpassword", "utilisateur12", "secretsecret", "abcdefghijkl");

    @Override
    public boolean isValid(String motDePasse, ConstraintValidatorContext contexte) {
        if (motDePasse == null) return true;

        if (motDePasse.length() < LONGUEUR_MINIMALE
                || motDePasse.length() > LONGUEUR_MAXIMALE) {
            return echouer(contexte, "Le mot de passe doit contenir entre "
                    + LONGUEUR_MINIMALE + " et " + LONGUEUR_MAXIMALE
                    + " caracteres. Une phrase facile a retenir convient.");
        }

        if (MOTS_DE_PASSE_COURANTS.contains(motDePasse.toLowerCase(Locale.ROOT))) {
            return echouer(contexte, "Ce mot de passe est trop courant et figure "
                    + "dans les listes utilisees par les attaquants. Choisissez-en "
                    + "un autre.");
        }

        return true;
    }

    /**
     * Remplace le message par defaut pour indiquer LAQUELLE des deux regles a
     * echoue : un refus sans motif pousse l'utilisateur a tatonner.
     */
    private boolean echouer(ConstraintValidatorContext contexte, String message) {
        contexte.disableDefaultConstraintViolation();
        contexte.buildConstraintViolationWithTemplate(message).addConstraintViolation();
        return false;
    }
}
