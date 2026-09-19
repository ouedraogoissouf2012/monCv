package com.cvmobile.validation;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import static java.lang.annotation.ElementType.ANNOTATION_TYPE;
import static java.lang.annotation.ElementType.FIELD;
import static java.lang.annotation.ElementType.PARAMETER;
import static java.lang.annotation.ElementType.RECORD_COMPONENT;

/**
 * Politique de mot de passe de l'application (issue #511).
 *
 * <p>Definition unique, appliquee partout ou un mot de passe est choisi :
 * inscription et reinitialisation. La politique etait auparavant recopiee dans
 * chaque DTO sous forme de {@code @Size(min = 6)} ; deux copies peuvent diverger
 * sans que rien ne le signale, et c'est precisement ce qu'une politique de
 * securite ne doit pas permettre.
 *
 * <p>La regle repose sur la LONGUEUR plutot que sur une composition imposee
 * (majuscule, chiffre, caractere special). Les exigences de composition poussent
 * a des mots de passe courts et previsibles — {@code Motdepasse1!} — la ou une
 * phrase de passe longue resiste bien mieux. Une liste des mots de passe les
 * plus courants complete le controle : la longueur seule n'empeche pas de
 * choisir {@code azertyuiop123}.
 */
@Documented
@Constraint(validatedBy = StrongPasswordValidator.class)
@Target({FIELD, PARAMETER, RECORD_COMPONENT, ANNOTATION_TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface StrongPassword {

    String message() default "Mot de passe trop faible";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
