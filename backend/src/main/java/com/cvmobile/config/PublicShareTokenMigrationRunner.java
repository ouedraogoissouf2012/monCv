package com.cvmobile.config;

import com.cvmobile.service.cv.PublicShareTokenMigrationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class PublicShareTokenMigrationRunner implements ApplicationRunner {
    private final PublicShareTokenMigrationService migrationService;

    @Override
    public void run(ApplicationArguments args) {
        int total = 0;
        int migrated;
        do {
            migrated = migrationService.migrateNextBatch();
            total += migrated;
        } while (migrated == PublicShareTokenMigrationService.BATCH_SIZE);

        if (total > 0) {
            log.info("Migration securisee de {} liens publics terminee", total);
        }
    }
}
