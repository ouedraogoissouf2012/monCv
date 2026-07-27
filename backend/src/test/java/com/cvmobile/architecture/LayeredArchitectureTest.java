package com.cvmobile.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.EvaluationResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Regles de frontiere du backend (ADR 003, issue #235).
 *
 * <p>Ces regles verrouillent la direction des dependances vers le domaine.
 * Certaines frontieres cibles n'existent pas encore physiquement (le domaine
 * partage le package {@code model} avec la persistance JPA) : les regles
 * correspondantes sont donc "gelees" avec une allowlist explicite des
 * violations actuelles. L'allowlist ne doit que decroitre, jamais grandir, et
 * disparaitra quand #255 separera domaine et adapters.
 */
class LayeredArchitectureTest {

    private static final JavaClasses PRODUCTION_CLASSES = new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("com.cvmobile");

    /**
     * Regle ACTIVE : un controller ne doit jamais dependre d'un repository.
     * Verifie a la redaction (2026-07-27) : zero violation. Cette regle protege
     * un acquis (la violation citee par #231/#255 a deja ete corrigee).
     */
    @Test
    @DisplayName("Aucun controller ne depend d'un repository")
    void controllersMustNotDependOnRepositories() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..controller..")
                .should().dependOnClassesThat().resideInAPackage("..repository..")
                .because("un controller doit passer par un service / port applicatif (ADR 003)");

        rule.check(PRODUCTION_CLASSES);
    }

    /**
     * Regle GELEE : le domaine ({@code model}) ne doit pas dependre de Spring
     * Security. Allowlist actuelle : {@code User} (implemente {@code UserDetails}).
     * A retirer quand un adapter Security portera cette responsabilite (#255).
     */
    @Test
    @DisplayName("Le domaine ne depend pas de Spring Security (hors allowlist)")
    void domainMustNotDependOnSpringSecurity() {
        ArchRule rule = noClasses()
                .that().resideInAPackage("..model..")
                .and().haveSimpleNameNotEndingWith("User") // allowlist gelee, #255
                .should().dependOnClassesThat()
                .resideInAPackage("org.springframework.security..")
                .because("le domaine doit ignorer le framework de securite (ADR 003)");

        rule.check(PRODUCTION_CLASSES);
    }

    /**
     * Test META : prouve qu'une violation EST detectee (exige par #235).
     * On applique la regle domaine->Spring Security SANS allowlist : la classe
     * reelle {@code User} doit alors la faire echouer. Si ce test cessait
     * d'echouer, la regle ne testerait plus rien.
     */
    @Test
    @DisplayName("La regle detecte bien une violation reelle (User/UserDetails)")
    void ruleActuallyDetectsAViolation() {
        ArchRule ruleWithoutAllowlist = noClasses()
                .that().resideInAPackage("..model..")
                .should().dependOnClassesThat()
                .resideInAPackage("org.springframework.security..");

        EvaluationResult result = ruleWithoutAllowlist.evaluate(PRODUCTION_CLASSES);

        if (!result.hasViolation()) {
            throw new AssertionError(
                    "La regle aurait du detecter la dependance reelle User -> UserDetails. "
                    + "Si User n'implemente plus UserDetails, retirer l'allowlist de "
                    + "domainMustNotDependOnSpringSecurity et supprimer ce test meta.");
        }
    }
}
