package com.cvmobile.security;

import com.cvmobile.config.RateLimitProperties;
import com.cvmobile.model.User;
import io.github.bucket4j.distributed.ExpirationAfterWriteStrategy;
import io.github.bucket4j.distributed.proxy.ProxyManager;
import io.github.bucket4j.redis.lettuce.Bucket4jLettuce;
import io.lettuce.core.RedisClient;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.codec.ByteArrayCodec;
import io.lettuce.core.codec.RedisCodec;
import io.lettuce.core.codec.StringCodec;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers(disabledWithoutDocker = true)
class RateLimitFilterRedisIntegrationTest {

    @Container
    private static final GenericContainer<?> REDIS = new GenericContainer<>(
            DockerImageName.parse("redis:7-alpine")
    ).withExposedPorts(6379);

    private static RedisClient firstClient;
    private static RedisClient secondClient;
    private static StatefulRedisConnection<String, byte[]> firstConnection;
    private static StatefulRedisConnection<String, byte[]> secondConnection;

    @BeforeAll
    static void connectClients() {
        String redisUrl = "redis://" + REDIS.getHost() + ":" + REDIS.getMappedPort(6379);
        firstClient = RedisClient.create(redisUrl);
        secondClient = RedisClient.create(redisUrl);
        firstConnection = firstClient.connect(redisCodec());
        secondConnection = secondClient.connect(redisCodec());
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @AfterAll
    static void closeClients() {
        firstConnection.close();
        secondConnection.close();
        firstClient.shutdown();
        secondClient.shutdown();
    }

    @Test
    void burstPartageEntreDeuxInstancesPuisRetourne429AvecRetryAfter() throws Exception {
        RateLimitProperties properties = properties();
        RateLimitFilter firstFilter = filter(proxy(firstConnection), properties);
        RateLimitFilter secondFilter = filter(proxy(secondConnection), properties);
        authenticateUser(99L);

        MockHttpServletResponse first = execute(firstFilter);
        MockHttpServletResponse second = execute(secondFilter);
        MockHttpServletResponse rejected = execute(firstFilter);

        assertThat(first.getStatus()).isEqualTo(200);
        assertThat(second.getStatus()).isEqualTo(200);
        assertThat(rejected.getStatus()).isEqualTo(429);
        assertThat(Long.parseLong(rejected.getHeader("Retry-After")))
                .isBetween(1L, properties.aiWindow().toSeconds());
    }

    private RateLimitFilter filter(
            ProxyManager<String> proxyManager,
            RateLimitProperties properties) {
        return new RateLimitFilter(
                properties,
                new RedisRateLimitService(proxyManager, properties),
                new SimpleMeterRegistry()
        );
    }

    private MockHttpServletResponse execute(RateLimitFilter filter) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/ai/enhance-cv");
        request.setRemoteAddr("203.0.113.10");
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }

    private static ProxyManager<String> proxy(
            StatefulRedisConnection<String, byte[]> connection) {
        return Bucket4jLettuce.casBasedBuilder(connection)
                .expirationAfterWrite(ExpirationAfterWriteStrategy
                        .basedOnTimeForRefillingBucketUpToMax(Duration.ofMinutes(1)))
                .build();
    }

    private static RedisCodec<String, byte[]> redisCodec() {
        return RedisCodec.of(StringCodec.UTF8, ByteArrayCodec.INSTANCE);
    }

    private RateLimitProperties properties() {
        return new RateLimitProperties(
                true,
                true,
                10,
                Duration.ofMinutes(1),
                2,
                Duration.ofSeconds(30),
                5,
                Duration.ofHours(1),
                60,
                Duration.ofMinutes(1),
                "redis://unused",
                "test:rate-limit:" + UUID.randomUUID() + ":"
        );
    }

    private void authenticateUser(Long id) {
        User user = User.builder()
                .id(id)
                .email("user@example.com")
                .password("unused")
                .role(User.Role.USER)
                .build();
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities())
        );
    }
}
