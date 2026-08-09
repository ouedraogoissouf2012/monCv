package com.cvmobile.integration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.output.ValidateResult;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;

class FlywayMigrationsTest extends PostgresIntegrationTest {

    private static Flyway flyway;
    private static final String SCHEMA = "flyway_contract";

    @BeforeAll
    static void migrateFreshDatabase() throws Exception {
        try (Connection connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword());
             var statement = connection.createStatement()) {
            statement.execute("DROP SCHEMA IF EXISTS " + SCHEMA + " CASCADE");
        }

        flyway = Flyway.configure()
                .dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
                .schemas(SCHEMA)
                .defaultSchema(SCHEMA)
                .locations("classpath:db/migration")
                .load();
        flyway.migrate();
    }

    @Test
    void appliesAllMigrationsOnFreshPostgresqlDatabase() throws Exception {
        long versionedMigrations = Arrays.stream(flyway.info().applied())
                .filter(info -> info.getVersion() != null)
                .count();
        assertThat(versionedMigrations).isEqualTo(15);

        try (Connection connection = DriverManager.getConnection(
                POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())) {
            assertThat(tableExists(connection, SCHEMA, "users")).isTrue();
            assertThat(tableExists(connection, SCHEMA, "cvs")).isTrue();
            assertThat(tableExists(connection, SCHEMA, "certifications")).isTrue();
            assertThat(tableExists(connection, SCHEMA, "job_applications")).isTrue();
            assertThat(tableExists(connection, SCHEMA, "uploaded_photos")).isTrue();
            assertThat(tableExists(connection, SCHEMA, "password_reset_token")).isTrue();
            assertThat(tableExists(connection, SCHEMA, "cv_views")).isFalse();
            assertThat(columnExists(connection, SCHEMA, "cvs", "public_token_hash")).isTrue();
        }
    }

    @Test
    void validatesMigrationChecksumsAfterMigration() {
        ValidateResult result = flyway.validateWithResult();

        assertThat(result.validationSuccessful).isTrue();
        assertThat(result.invalidMigrations).isEmpty();
    }

    private boolean tableExists(Connection connection, String schema, String tableName) throws Exception {
        try (ResultSet tables = connection.getMetaData().getTables(null, schema, tableName, new String[]{"TABLE"})) {
            return tables.next();
        }
    }

    private boolean columnExists(
            Connection connection, String schema, String tableName, String columnName
    ) throws Exception {
        try (ResultSet columns = connection.getMetaData()
                .getColumns(null, schema, tableName, columnName)) {
            return columns.next();
        }
    }
}
