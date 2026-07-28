package com.cvmobile.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Purete du domaine CV migre (issue #255, ADR 003).
 *
 * <p>Contrairement aux regles gelees de {@link LayeredArchitectureTest} (qui
 * tolerent l'ancien monolithe via allowlist), ce module est neuf : il doit etre
 * pur des le premier commit. Ces regles n'ont donc <strong>aucune
 * allowlist</strong> — toute fuite de framework dans {@code cv.domain} fait
 * echouer la construction.
 */
@DisplayName("Le domaine CV migre est pur (aucune fuite de framework)")
class CvDomainPurityTest {

    private static final String CV_DOMAIN = "com.cvmobile.cv.domain..";

    private static final JavaClasses CV_DOMAIN_CLASSES = new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("com.cvmobile.cv.domain");

    @Test
    @DisplayName("ne depend pas de Spring")
    void mustNotDependOnSpring() {
        rule("org.springframework..", "Spring").check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend pas de JPA / Jakarta Persistence")
    void mustNotDependOnJpa() {
        rule("jakarta.persistence..", "JPA").check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend pas de la validation Jakarta")
    void mustNotDependOnJakartaValidation() {
        rule("jakarta.validation..", "Jakarta Validation").check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend pas d'Hibernate")
    void mustNotDependOnHibernate() {
        rule("org.hibernate..", "Hibernate").check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend pas de Lombok")
    void mustNotDependOnLombok() {
        rule("lombok..", "Lombok").check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend pas de Jackson (serialisation web)")
    void mustNotDependOnJackson() {
        rule("com.fasterxml.jackson..", "Jackson").check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend pas d'un type web (servlet / multipart)")
    void mustNotDependOnWeb() {
        noClasses()
                .that().resideInAPackage(CV_DOMAIN)
                .should().dependOnClassesThat()
                .resideInAnyPackage(
                        "org.springframework.web..",
                        "jakarta.servlet..")
                .because("le domaine ignore la couche web (ADR 003)")
                .check(CV_DOMAIN_CLASSES);
    }

    @Test
    @DisplayName("ne depend d'aucun autre module applicatif (isolation)")
    void mustNotDependOnOtherModules() {
        noClasses()
                .that().resideInAPackage(CV_DOMAIN)
                .should().dependOnClassesThat()
                .resideInAnyPackage(
                        "com.cvmobile.model..",
                        "com.cvmobile.repository..",
                        "com.cvmobile.controller..",
                        "com.cvmobile.dto..",
                        "com.cvmobile.security..")
                .because("le domaine CV ne connait ni l'ancien monolithe ni un adapter")
                .check(CV_DOMAIN_CLASSES);
    }

    // ── Couche application : depend du port + domaine, jamais d'un adapter ──

    private static final String CV_APPLICATION = "com.cvmobile.cv.application..";

    private static final JavaClasses CV_MODULE_CLASSES = new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("com.cvmobile.cv");

    @Test
    @DisplayName("l'application ne depend pas des adapters (dependances vers l'interieur)")
    void applicationMustNotDependOnAdapters() {
        noClasses()
                .that().resideInAPackage(CV_APPLICATION)
                .should().dependOnClassesThat().resideInAPackage("com.cvmobile.cv.adapter..")
                .because("les use cases dependent du port (interface), jamais d'un adapter (ADR 003)")
                .check(CV_MODULE_CLASSES);
    }

    @Test
    @DisplayName("l'application ne depend d'aucune infrastructure de persistance ni transport")
    void applicationMustNotDependOnInfrastructure() {
        noClasses()
                .that().resideInAPackage(CV_APPLICATION)
                .should().dependOnClassesThat()
                .resideInAnyPackage(
                        "com.cvmobile.repository..",
                        "com.cvmobile.model..",
                        "com.cvmobile.dto..",
                        "com.cvmobile.mapper..",
                        "jakarta.persistence..",
                        "org.springframework.web..")
                .because("la couche application ignore JPA, les DTOs web et la couche transport (ADR 003)")
                .check(CV_MODULE_CLASSES);
    }

    private static ArchRule rule(String forbiddenPackage, String label) {
        return noClasses()
                .that().resideInAPackage(CV_DOMAIN)
                .should().dependOnClassesThat().resideInAPackage(forbiddenPackage)
                .because("le domaine CV doit ignorer " + label + " (ADR 003, #255)");
    }
}
