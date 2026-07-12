package com.cvmobile.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.PropertySource;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Valide au demarrage que les secrets critiques sont bien charges.
 *
 * En profil dev : log warning + mode degrade autorise.
 * En profil prod : throw IllegalStateException → l'app crash (container restart).
 *
 * Affiche aussi une banniere montrant la source de chaque secret pour le debug
 * (ex: probleme de chargement spring-dotenv si on lance depuis un mauvais CWD).
 *
 * Ne log JAMAIS la valeur du secret, seulement la longueur et la source.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AppStartupValidator implements ApplicationListener<ApplicationReadyEvent> {

    private static final List<String> ALL_SECRETS = List.of(
            "DEEPSEEK_API_KEY",
            "JWT_SECRET",
            "DB_PASSWORD",
            "ALLOWED_ORIGINS");

    /** Secrets qui DOIVENT etre presents en prod (fail-fast). */
    private static final List<String> PROD_REQUIRED = List.of(
            "DEEPSEEK_API_KEY",
            "JWT_SECRET",
            "DB_PASSWORD",
            "ALLOWED_ORIGINS");

    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {
        ConfigurableEnvironment env = (ConfigurableEnvironment) event.getApplicationContext().getEnvironment();
        String[] profiles = env.getActiveProfiles();
        String profile = profiles.length > 0 ? profiles[0] : "default";

        // Pas de validation en profil test (H2 + mocks)
        if ("test".equals(profile)) return;

        log.info("=== CV Mobile Startup Config ===");
        log.info("Profile: {}", profile);

        List<String> missing = new java.util.ArrayList<>();

        for (String key : ALL_SECRETS) {
            String value = env.getProperty(key);
            boolean present = value != null && !value.isBlank();
            String source = findSource(env, key);

            if (present) {
                log.info("{} {} OK (source: {}, length={})",
                        key, padding(key), source, value.length());
            } else {
                log.warn("{} {} MISSING (source: none)", key, padding(key));
                missing.add(key);
            }
        }

        log.info("================================");

        // Fail-fast en prod si un secret critique manque
        if ("prod".equals(profile)) {
            List<String> critical = missing.stream()
                    .filter(PROD_REQUIRED::contains)
                    .toList();
            if (!critical.isEmpty()) {
                throw new IllegalStateException(
                        "Impossible de demarrer en profil 'prod' : secrets manquants " + critical
                        + ". Verifiez la configuration de l'orchestrateur ou du secrets manager.");
            }
        }

        // Warnings actionnables en dev
        if (missing.contains("DEEPSEEK_API_KEY")) {
            log.warn("⚠ DeepSeek desactive (mode degrade). "
                    + "Ajoutez DEEPSEEK_API_KEY dans backend/.env ou exportez-la dans votre shell.");
        }
    }

    /**
     * Trouve la PropertySource Spring qui a fourni cette cle.
     * Utile pour diagnostiquer les problemes de chargement (ex: .env pas trouve).
     */
    private String findSource(ConfigurableEnvironment env, String key) {
        for (PropertySource<?> ps : env.getPropertySources()) {
            if (ps.containsProperty(key)) {
                String name = ps.getName();
                if (name.contains("dotenv")) return "dotenv";
                if (name.contains("systemEnvironment")) return "systemEnvironment";
                if (name.contains("systemProperties")) return "systemProperties";
                if (name.contains("application")) return "application.yml";
                return name;
            }
        }
        return "none";
    }

    /** Aligne les cles pour que la banniere soit lisible. */
    private String padding(String key) {
        int maxLen = ALL_SECRETS.stream().mapToInt(String::length).max().orElse(20);
        int dots = Math.max(3, maxLen - key.length() + 3);
        return ".".repeat(dots);
    }
}
