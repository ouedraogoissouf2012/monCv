package com.cvmobile.observability;

import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CorrelationIdFilterTest {

    private final MockMvc mvc = MockMvcBuilders
            .standaloneSetup(new ProbeController())
            .addFilters(new CorrelationIdFilter())
            .build();

    @Test
    void generatesCorrelationIdWhenMissing() throws Exception {
        mvc.perform(get("/test/probe"))
                .andExpect(status().isOk())
                .andExpect(header().string(
                        CorrelationIdFilter.HEADER_NAME,
                        matchesPattern("^[0-9a-f\\-]{36}$")));
    }

    @Test
    void reusesIncomingCorrelationId() throws Exception {
        mvc.perform(get("/test/probe")
                        .header(CorrelationIdFilter.HEADER_NAME, "req-123"))
                .andExpect(status().isOk())
                .andExpect(header().string(CorrelationIdFilter.HEADER_NAME, "req-123"));
    }

    @RestController
    static class ProbeController {

        @GetMapping("/test/probe")
        ResponseEntity<Void> probe(
                @RequestHeader(value = CorrelationIdFilter.HEADER_NAME, required = false) String ignored) {
            return ResponseEntity.ok().build();
        }
    }
}
