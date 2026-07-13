package com.cvmobile.exception;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
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

    private final MockMvc mvc = MockMvcBuilders
            .standaloneSetup(new FailingController())
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void runtimeExceptionReturnsGeneric500AndKeepsDetailsInLogs(CapturedOutput output) throws Exception {
        MvcResult result = mvc.perform(get("/test/runtime-failure"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.status").value(500))
                .andExpect(jsonPath("$.code").value("INTERNAL_ERROR"))
                .andExpect(jsonPath("$.message").value(PUBLIC_MESSAGE))
                .andExpect(jsonPath("$.details").doesNotExist())
                .andReturn();

        assertThat(result.getResponse().getContentAsString())
                .doesNotContain("10.0.0.5")
                .doesNotContain("5432")
                .doesNotContain("DB connection failed");
        assertThat(output).contains(INTERNAL_MESSAGE);
    }

    @RestController
    private static class FailingController {

        @GetMapping("/test/runtime-failure")
        void throwRuntimeException() {
            throw new RuntimeException(INTERNAL_MESSAGE);
        }
    }
}
