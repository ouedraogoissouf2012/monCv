package com.cvmobile.security;

import com.cvmobile.config.RequestBodyLimitProperties;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class JsonRequestBodyLimitFilterTest {
    private final JsonRequestBodyLimitFilter filter = new JsonRequestBodyLimitFilter(
            new RequestBodyLimitProperties(32, 64));

    @Test
    void rejectsDeclaredOrStreamedJsonAboveTheConfiguredLimit() throws Exception {
        MockHttpServletRequest streamed = new MockHttpServletRequest("POST", "/api/auth/login") {
            @Override
            public int getContentLength() {
                return -1;
            }

            @Override
            public long getContentLengthLong() {
                return -1;
            }
        };
        streamed.setContentType("application/json");
        streamed.setContent("x".repeat(33).getBytes(StandardCharsets.UTF_8));
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        filter.doFilter(streamed, response, chain);

        assertThat(response.getStatus()).isEqualTo(413);
        assertThat(response.getContentAsString()).contains("REQUEST_TOO_LARGE");
        verify(chain, never()).doFilter(streamed, response);
    }

    @Test
    void allowsLargerCvLimitAndReplaysTheBodyToDownstreamCode() throws Exception {
        MockHttpServletRequest request = request("/api/cvs", "{\"titre\":\"CV\"}");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = (wrappedRequest, ignored) -> assertThat(
                wrappedRequest.getInputStream().readAllBytes())
                .isEqualTo(request.getContentAsByteArray());

        filter.doFilter(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(200);
    }

    @Test
    void ignoresNonJsonAndReadOnlyRequests() throws Exception {
        MockHttpServletRequest request = request("/api/cvs", "x".repeat(100));
        request.setMethod("GET");
        FilterChain chain = mock(FilterChain.class);
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, chain);

        verify(chain).doFilter(request, response);
    }

    private MockHttpServletRequest request(String uri, String body) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", uri);
        request.setContentType("application/json; charset=utf-8");
        request.setContent(body.getBytes(StandardCharsets.UTF_8));
        return request;
    }
}
