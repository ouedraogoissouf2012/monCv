package com.cvmobile.config;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiServiceException;
import com.cvmobile.service.ai.client.DeepSeekClient;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.Profiles;
import org.springframework.core.env.PropertySource;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Valide au demarrage que les secrets critiques sont bien charges.
 *
 * En profil dev : DB_PASSWORD obligatoire, services optionnels en mode degrade.
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

    private static final List<String> NON_TEST_REQUIRED = List.of("DB_PASSWORD");

    private final ConfigurableEnvironment env;

    @Autowired(required = false)
    private DeepSeekClient deepSeekClient;

    @PostConstruct
    void validateSecrets() {
        if (env.acceptsProfiles(Profiles.of("test"))) return;

        String[] profiles = env.getActiveProfiles();
        String profile = profiles.length > 0 ? String.join(",", profiles) : "default";
        boolean production = env.acceptsProfiles(Profiles.of("prod"));

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

        List<String> required = production ? PROD_REQUIRED : NON_TEST_REQUIRED;
        List<String> critical = missing.stream()
                .filter(required::contains)
                .toList();
        if (!critical.isEmpty()) {
            throw new IllegalStateException(
                    "Impossible de demarrer avec le profil '" + profile + "' : secrets manquants " + critical
                    + ". Verifiez les variables d'environnement ou le secrets manager.");
        }

        // Warnings actionnables en dev
        if (missing.contains("DEEPSEEK_API_KEY")) {
            log.warn("⚠ DeepSeek desactive (mode degrade). "
                    + "Ajoutez DEEPSEEK_API_KEY dans backend/.env ou exportez-la dans votre shell.");
        }
    }

    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {
        if (env.acceptsProfiles(Profiles.of("test")) || deepSeekClient == null) {
            return;
        }

        boolean production = env.acceptsProfiles(Profiles.of("prod"));
        try {
            deepSeekClient.complete("Reponds uniquement par OK.", 8);
            log.info("DeepSeek startup probe OK");
        } catch (AiKeyInvalidException e) {
            if (production) {
                throw new IllegalStateException(
                        "DeepSeek a refuse DEEPSEEK_API_KEY au demarrage", e);
            }
            log.warn("DeepSeek startup probe: cle invalide, demarrage en mode degrade");
        } catch (AiServiceException e) {
            log.warn("DeepSeek startup probe transitoire: code={} provider={}",
                    e.getErrorCode(), e.getProviderName());
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
