package com.cvmobile.config;

import okhttp3.mockwebserver.MockResponse;
import okhttp3.mockwebserver.MockWebServer;
import okhttp3.mockwebserver.SocketPolicy;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.Status;
import org.springframework.boot.web.client.RestTemplateBuilder;

import java.io.IOException;
import java.net.ServerSocket;

import static org.assertj.core.api.Assertions.assertThat;

class DeepSeekHealthIndicatorTest {

    private MockWebServer server;

    @BeforeEach
    void startServer() throws IOException {
        server = new MockWebServer();
        server.start();
    }

    @AfterEach
    void stopServer() throws IOException {
        server.shutdown();
    }

    @Test
    void returnsUpWhenDeepSeekResponds200() {
        server.enqueue(new MockResponse().setResponseCode(200).setBody("{}"));

        Health health = indicator(server.url("/v1").toString()).health();

        assertThat(health.getStatus()).isEqualTo(Status.UP);
        assertThat(health.getDetails())
                .containsEntry("model", "deepseek-chat")
                .containsEntry("baseUrl", server.url("/v1").toString());
    }

    @Test
    void returnsOutOfServiceWhenApiKeyIsRejected() {
        server.enqueue(new MockResponse().setResponseCode(401));

        Health health = indicator(server.url("/v1").toString()).health();

        assertThat(health.getStatus()).isEqualTo(Status.OUT_OF_SERVICE);
        assertThat(health.getDetails())
                .containsEntry("reason", "api-key-invalid")
                .containsEntry("httpStatus", 401);
    }

    @Test
    void returnsDownWhenProviderResponds5xx() {
        server.enqueue(new MockResponse().setResponseCode(503));

        Health health = indicator(server.url("/v1").toString()).health();

        assertThat(health.getStatus()).isEqualTo(Status.DOWN);
        assertThat(health.getDetails()).containsEntry("reason", "probe-failed");
    }

    @Test
    void returnsDownWhenConnectionIsRefused() throws IOException {
        int unusedPort;
        try (ServerSocket socket = new ServerSocket(0)) {
            unusedPort = socket.getLocalPort();
        }

        Health health = indicator("http://127.0.0.1:" + unusedPort + "/v1").health();

        assertThat(health.getStatus()).isEqualTo(Status.DOWN);
        assertThat(health.getDetails()).containsEntry("reason", "probe-failed");
    }

    @Test
    void returnsDownWhenProviderTimesOut() {
        server.enqueue(new MockResponse().setSocketPolicy(SocketPolicy.NO_RESPONSE));

        Health health = indicator(server.url("/v1").toString()).health();

        assertThat(health.getStatus()).isEqualTo(Status.DOWN);
        assertThat(health.getDetails()).containsEntry("reason", "probe-failed");
    }

    @Test
    void cachesProbeForSixtySeconds() {
        server.enqueue(new MockResponse().setResponseCode(200).setBody("{}"));
        DeepSeekHealthIndicator indicator = indicator(server.url("/v1").toString());

        Health first = indicator.health();
        Health second = indicator.health();

        assertThat(first.getStatus()).isEqualTo(Status.UP);
        assertThat(second.getStatus()).isEqualTo(Status.UP);
        assertThat(server.getRequestCount()).isEqualTo(1);
    }

    @Test
    void returnsDownWithoutApiKeyAndDoesNotCallProvider() {
        DeepSeekHealthIndicator indicator = new DeepSeekHealthIndicator(
                " ", server.url("/v1").toString(), "deepseek-chat", new RestTemplateBuilder());

        Health health = indicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.DOWN);
        assertThat(health.getDetails()).containsEntry("reason", "api-key-missing");
        assertThat(server.getRequestCount()).isZero();
    }

    private DeepSeekHealthIndicator indicator(String baseUrl) {
        return new DeepSeekHealthIndicator(
                "test-api-key", baseUrl, "deepseek-chat", new RestTemplateBuilder());
    }
}
