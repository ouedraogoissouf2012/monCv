package com.cvmobile.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;

import static org.assertj.core.api.Assertions.assertThat;

class CorsConfigTest {

    @Test
    void corsConfiguration_devraitAccepterLesOriginesLocalesConfigurees() {
        CorsConfig corsConfig = new CorsConfig();
        ReflectionTestUtils.setField(corsConfig, "allowedOrigins",
                "http://localhost:*, http://127.0.0.1:*");

        CorsConfiguration configuration = getConfiguration(corsConfig);

        assertThat(configuration.checkOrigin("http://localhost:30589"))
                .isEqualTo("http://localhost:30589");
        assertThat(configuration.checkOrigin("http://127.0.0.1:53816"))
                .isEqualTo("http://127.0.0.1:53816");
        assertThat(configuration.getAllowCredentials()).isFalse();
    }

    @Test
    void corsConfiguration_devraitRefuserUneOrigineNonConfiguree() {
        CorsConfig corsConfig = new CorsConfig();
        ReflectionTestUtils.setField(corsConfig, "allowedOrigins", "http://localhost:3002");

        CorsConfiguration configuration = getConfiguration(corsConfig);

        assertThat(configuration.checkOrigin("https://example.com")).isNull();
    }

    private CorsConfiguration getConfiguration(CorsConfig corsConfig) {
        CorsConfigurationSource source = corsConfig.corsConfigurationSource();
        return source.getCorsConfiguration(new MockHttpServletRequest("OPTIONS", "/api/auth/login"));
    }
}
