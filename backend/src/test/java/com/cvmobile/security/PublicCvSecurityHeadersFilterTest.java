package com.cvmobile.security;

import org.junit.jupiter.api.Test;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

class PublicCvSecurityHeadersFilterTest {
    private final PublicCvSecurityHeadersFilter filter = new PublicCvSecurityHeadersFilter();

    @Test
    void appliesNoStoreAntiIndexingAndContentProtectionsToEveryPublicResponse()
            throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest(
                "GET", "/api/cvs/public/invalid-token");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, (req, res) ->
                ((HttpServletResponse) res).setStatus(404));

        assertThat(response.getStatus()).isEqualTo(404);
        assertThat(response.getHeader("Cache-Control")).isEqualTo("no-store, max-age=0");
        assertThat(response.getHeader("Referrer-Policy")).isEqualTo("no-referrer");
        assertThat(response.getHeader("X-Content-Type-Options")).isEqualTo("nosniff");
        assertThat(response.getHeader("X-Frame-Options")).isEqualTo("DENY");
        assertThat(response.getHeader("X-Robots-Tag")).contains("noindex");
        assertThat(response.getHeader("Content-Security-Policy"))
                .contains("frame-ancestors 'none'");
    }

    @Test
    void leavesPrivateApiResponsesUntouched() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/cvs/12");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, new MockFilterChain());

        assertThat(response.getHeader("X-Robots-Tag")).isNull();
    }
}
