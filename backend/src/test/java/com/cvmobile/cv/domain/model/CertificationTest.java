package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Certification (value object domaine)")
class CertificationTest {

    @Test
    @DisplayName("cree une certification complete")
    void createsFullCertification() {
        Certification cert = Certification.of(
                9L, "AWS SAA", "Amazon",
                LocalDate.of(2021, 3, 1), LocalDate.of(2024, 3, 1),
                "https://verify.aws/abc");

        assertThat(cert.id()).isEqualTo(9L);
        assertThat(cert.nom()).isEqualTo("AWS SAA");
        assertThat(cert.organisme()).isEqualTo("Amazon");
        assertThat(cert.dateObtention()).isEqualTo(LocalDate.of(2021, 3, 1));
        assertThat(cert.dateExpiration()).isEqualTo(LocalDate.of(2024, 3, 1));
        assertThat(cert.credentialUrl()).isEqualTo("https://verify.aws/abc");
    }

    @Test
    @DisplayName("accepte les champs optionnels a null")
    void allowsOptionalNull() {
        Certification cert = Certification.of(null, "Cert", null, null, null, null);

        assertThat(cert.organisme()).isNull();
        assertThat(cert.dateExpiration()).isNull();
        assertThat(cert.credentialUrl()).isNull();
    }

    @Test
    @DisplayName("normalise et convertit les blancs en null")
    void normalisesText() {
        Certification cert = Certification.of(
                null, "  AWS  ", "   ", null, null, "  url  ");

        assertThat(cert.nom()).isEqualTo("AWS");
        assertThat(cert.organisme()).isNull();
        assertThat(cert.credentialUrl()).isEqualTo("url");
    }

    @Test
    @DisplayName("egalite par valeur")
    void valueEquality() {
        Certification a = Certification.of(1L, "AWS", "Amazon", null, null, "u");
        Certification b = Certification.of(1L, "AWS", "Amazon", null, null, "u");

        assertThat(a).isEqualTo(b).hasSameHashCodeAs(b);
    }
}
