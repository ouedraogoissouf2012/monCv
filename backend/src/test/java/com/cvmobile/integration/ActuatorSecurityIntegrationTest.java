package com.cvmobile.integration;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "management.prometheus.allowed-ip-ranges=127.0.0.1/32",
        "management.prometheus.metrics.export.enabled=true"
})
class ActuatorSecurityIntegrationTest {

    @Autowired
    private MockMvc mvc;

    @Test
    void anonymousCanAccessMinimalLivenessProbe() throws Exception {
        mvc.perform(get("/actuator/health/liveness"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.components").doesNotExist())
                .andExpect(jsonPath("$.details").doesNotExist());
    }

    @Test
    void anonymousCanAccessMinimalReadinessProbe() throws Exception {
        mvc.perform(get("/actuator/health/readiness"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.components").doesNotExist())
                .andExpect(jsonPath("$.details").doesNotExist());
    }

    @Test
    void anonymousCannotAccessInfo() throws Exception {
        mvc.perform(get("/actuator/info"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void anonymousCannotAccessMetrics() throws Exception {
        mvc.perform(get("/actuator/metrics"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void anonymousCannotAccessAggregateHealthOrComponents() throws Exception {
        mvc.perform(get("/actuator/health"))
                .andExpect(status().isUnauthorized());
        mvc.perform(get("/actuator/health/db"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void regularUserCannotAccessMetrics() throws Exception {
        mvc.perform(get("/actuator/metrics").with(user("user@example.com").roles("USER")))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanAccessMetrics() throws Exception {
        mvc.perform(get("/actuator/metrics").with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk());
    }

    @Test
    void prometheusAllowsConfiguredInternalAddress() throws Exception {
        mvc.perform(get("/actuator/prometheus").with(request -> {
                    request.setRemoteAddr("127.0.0.1");
                    return request;
                }))
                .andExpect(status().isOk());
    }

    @Test
    void prometheusRejectsUntrustedAddress() throws Exception {
        mvc.perform(get("/actuator/prometheus").with(request -> {
                    request.setRemoteAddr("203.0.113.10");
                    return request;
                }))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void productionProfileDoesNotExposeInfo() throws Exception {
        var propertySource = new YamlPropertySourceLoader()
                .load("application-prod", new ClassPathResource("application-prod.yml"))
                .get(0);

        assertThat(propertySource.getProperty("management.endpoints.web.exposure.include"))
                .isEqualTo("health,metrics,prometheus");
    }
}
