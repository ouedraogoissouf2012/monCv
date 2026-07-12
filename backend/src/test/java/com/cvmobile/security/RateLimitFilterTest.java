package com.cvmobile.security;

import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

class RateLimitFilterTest {

    @Test
    void limiteLesEndpointsIaParIp() throws ServletException, IOException {
        RateLimitFilter filter = new RateLimitFilter();

        MockHttpServletResponse lastResponse = null;
        for (int i = 0; i < 21; i++) {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/ai/enhance-cv");
            request.setRemoteAddr("203.0.113.10");
            lastResponse = new MockHttpServletResponse();

            filter.doFilter(request, lastResponse, new MockFilterChain());
        }

        assertThat(lastResponse).isNotNull();
        assertThat(lastResponse.getStatus()).isEqualTo(429);
        assertThat(lastResponse.getHeader("Retry-After")).isEqualTo("60");
    }

    @Test
    void ignoreLesEndpointsNonSensibles() throws ServletException, IOException {
        RateLimitFilter filter = new RateLimitFilter();
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health/local");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertThat(response.getStatus()).isEqualTo(200);
    }
}
