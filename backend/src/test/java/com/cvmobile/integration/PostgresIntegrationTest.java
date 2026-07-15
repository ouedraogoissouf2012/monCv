package com.cvmobile.integration;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.concurrent.atomic.AtomicBoolean;

@Testcontainers(disabledWithoutDocker = true)
abstract class PostgresIntegrationTest {

    private static final AtomicBoolean SCHEMA_RESET = new AtomicBoolean();

    @Container
    protected static final PostgreSQLContainer<?> POSTGRES =
            new SharedPostgreSQLContainer("postgres:17-alpine")
                    .withDatabaseName("cvmobile_test")
                    .withUsername("postgres")
                    .withPassword("test")
                    .withReuse(true);

    @Autowired(required = false)
    private Flyway flyway;

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("spring.flyway.enabled", () -> true);
    }

    @BeforeAll
    static void resetSharedSchemaOnce() {
        if (!SCHEMA_RESET.compareAndSet(false, true)) return;

        Flyway resetFlyway = Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .schemas("public")
                .defaultSchema("public")
                .cleanDisabled(false)
                .locations("classpath:db/migration")
                .load();
        resetFlyway.clean();
        resetFlyway.migrate();
    }

    @BeforeEach
    void applyMigrations() {
        if (flyway != null) flyway.migrate();
    }

    private static final class SharedPostgreSQLContainer extends PostgreSQLContainer<SharedPostgreSQLContainer> {

        private SharedPostgreSQLContainer(String imageName) {
            super(imageName);
        }

        @Override
        public void stop() {
            // The JUnit extension sees this field once per subclass; final cleanup follows the reuse policy.
        }
    }
}
