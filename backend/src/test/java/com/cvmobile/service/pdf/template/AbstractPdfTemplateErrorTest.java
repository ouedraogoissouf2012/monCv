package com.cvmobile.service.pdf.template;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.PdfGenerationException;
import com.cvmobile.service.pdf.style.PdfTheme;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

/// Chemin d'ERREUR de AbstractPdfTemplate (issue #258).
///
/// Les tests de contrat des templates concrets ne couvrent que le rendu reussi.
/// Ici on verifie qu'une defaillance interne du rendu est encapsulee dans une
/// PdfGenerationException typee nommant le template — sans exposer la cause brute.
class AbstractPdfTemplateErrorTest {

    /// Sous-classe volontairement defaillante : un theme null provoque une NPE
    /// des le debut du rendu (dans le bloc try), independamment du detail d'un
    /// renderer de section.
    private static final class BrokenTemplate extends AbstractPdfTemplate {
        @Override
        protected PdfTheme theme() {
            return null;
        }

        @Override
        public com.cvmobile.model.PdfTemplate type() {
            return com.cvmobile.model.PdfTemplate.MODERNE;
        }
    }

    @Test
    void render_defaillanceInterne_estEncapsuleeEnPdfGenerationExceptionNommee() {
        assertThatThrownBy(
                () -> new BrokenTemplate().render(CvResponse.builder().build()))
                .isInstanceOf(PdfGenerationException.class)
                .hasMessageContaining("MODERNE"); // le message nomme le template
    }
}
