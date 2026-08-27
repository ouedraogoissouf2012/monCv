package com.cvmobile.exception;

import com.cvmobile.observability.CorrelationIdFilter;
import jakarta.persistence.OptimisticLockException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(OutputCaptureExtension.class)
class GlobalExceptionHandlerTest {

    private static final String INTERNAL_MESSAGE = "DB connection failed at 10.0.0.5:5432";
    private static final String PUBLIC_MESSAGE =
            "Une erreur s'est produite. Si le problème persiste, contactez le support.";
    private static final String CONFLICT_MESSAGE =
            "Ce contenu a ete modifie entre-temps. Rechargez-le puis reappliquez vos changements.";

    private final MockMvc mvc = MockMvcBuilders
            .standaloneSetup(new FailingController())
            .setControllerAdvice(new GlobalExceptionHandler())
            .addFilters(new CorrelationIdFilter())
            .build();

    @Test
    void runtimeExceptionReturnsGeneric500AndKeepsDetailsInLogs(CapturedOutput output) throws Exception {
        MvcResult result = mvc.perform(get("/test/runtime-failure"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.status").value(500))
                .andExpect(jsonPath("$.code").value("INTERNAL_ERROR"))
                .andExpect(jsonPath("$.message").value(PUBLIC_MESSAGE))
                .andExpect(jsonPath("$.correlationId").isString())
                .andExpect(jsonPath("$.details").doesNotExist())
                .andReturn();

        assertThat(result.getResponse().getContentAsString())
                .doesNotContain("10.0.0.5")
                .doesNotContain("5432")
                .doesNotContain("DB connection failed");
        assertThat(result.getResponse().getHeader(CorrelationIdFilter.HEADER_NAME)).isNotBlank();
        assertThat(output).contains(INTERNAL_MESSAGE);
        assertThat(output).contains("correlationId=");
    }

    /**
     * Issue #506 : un conflit d'edition concurrente est un conflit metier, pas
     * une panne serveur. Le client doit recevoir 409 (recharger puis rejouer),
     * jamais le 500 generique de la branche de repli.
     */
    @Test
    void optimisticLockFailureReturns409RatherThanGeneric500() throws Exception {
        mvc.perform(get("/test/optimistic-lock-failure"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.code").value("CONCURRENT_MODIFICATION"))
                .andExpect(jsonPath("$.message").value(CONFLICT_MESSAGE))
                .andExpect(jsonPath("$.correlationId").isString());
    }

    /** Meme traitement si l'echec remonte non traduit depuis le fournisseur JPA. */
    @Test
    void untranslatedJpaOptimisticLockAlsoReturns409() throws Exception {
        mvc.perform(get("/test/jpa-optimistic-lock-failure"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("CONCURRENT_MODIFICATION"));
    }

    /** Le conflit ne divulgue ni table, ni identifiant, ni revision attendue. */
    @Test
    void optimisticLockFailureKeepsPersistenceDetailsOutOfTheResponse() throws Exception {
        MvcResult result = mvc.perform(get("/test/optimistic-lock-failure")).andReturn();

        assertThat(result.getResponse().getContentAsString())
                .doesNotContain("cvs")
                .doesNotContain("Row was updated or deleted by another transaction");
    }

    @RestController
    private static class FailingController {

        @GetMapping("/test/runtime-failure")
        void throwRuntimeException() {
            throw new RuntimeException(INTERNAL_MESSAGE);
        }

        @GetMapping("/test/optimistic-lock-failure")
        void throwOptimisticLockingFailure() {
            throw new ObjectOptimisticLockingFailureException(
                    "Row was updated or deleted by another transaction (table cvs, id 42)",
                    new RuntimeException("StaleStateException"));
        }

        @GetMapping("/test/jpa-optimistic-lock-failure")
        void throwJpaOptimisticLock() {
            throw new OptimisticLockException("cvs#42");
        }
    }
}
