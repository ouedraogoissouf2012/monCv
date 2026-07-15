package com.cvmobile.integration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.output.ValidateResult;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers(disabledWithoutDocker = true)
class FlywayMigrationsTest {

    @Container
    private static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>("postgres:16-alpine");

    private static Flyway flyway;

    @BeforeAll
    static void migrateFreshDatabase() {
        flyway = Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .locations("classpath:db/migration")
                .load();
        flyway.migrate();
    }

    @Test
    void appliesAllMigrationsOnFreshPostgresqlDatabase() throws Exception {
        assertThat(flyway.info().applied()).hasSize(11);

        try (Connection connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())) {
            assertThat(tableExists(connection, "users")).isTrue();
            assertThat(tableExists(connection, "cvs")).isTrue();
            assertThat(tableExists(connection, "certifications")).isTrue();
            assertThat(tableExists(connection, "job_applications")).isTrue();
        }
    }

    @Test
    void validatesMigrationChecksumsAfterMigration() {
        ValidateResult result = flyway.validateWithResult();

        assertThat(result.validationSuccessful).isTrue();
        assertThat(result.invalidMigrations).isEmpty();
    }

    private boolean tableExists(Connection connection, String tableName) throws Exception {
        try (ResultSet tables = connection.getMetaData().getTables(null, "public", tableName, new String[]{"TABLE"})) {
            return tables.next();
        }
    }
}
