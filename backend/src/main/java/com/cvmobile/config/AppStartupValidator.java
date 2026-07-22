package com.cvmobile.config;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiServiceException;
import com.cvmobile.service.ai.client.DeepSeekClient;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.EnumMap;
import java.util.List;
import java.util.Set;

/**
 * Valide au demarrage que les secrets critiques sont bien charges.
 *
 * En profil dev : DB_PASSWORD obligatoire, services optionnels en mode degrade.
 * En profil prod : une configuration invalide arrete le demarrage.
 *
 * La banniere indique seulement si un reglage suivi est present. Elle ne log
 * jamais la valeur, la longueur ou la source d'un secret.
 */
@Slf4j
@Component
public class AppStartupValidator implements ApplicationListener<ApplicationReadyEvent> {

    private static final List<ProductionSetting> TRACKED_SETTINGS = Arrays.stream(
            ProductionSetting.values()).filter(ProductionSetting::trackedAtStartup).toList();

    private final ConfigurableEnvironment env;
    private final ProductionConfigurationPolicy productionPolicy;

    @Autowired(required = false)
    private DeepSeekClient deepSeekClient;

    AppStartupValidator(
            ConfigurableEnvironment env,
            ProductionConfigurationPolicy productionPolicy
    ) {
        this.env = env;
        this.productionPolicy = productionPolicy;
    }

    @PostConstruct
    void validateSecrets() {
        ProductionConfiguration configuration = snapshot();
        productionPolicy.validate(configuration);
        if (configuration.activeProfiles().contains("test")) return;

        String[] profiles = env.getActiveProfiles();
        String profile = profiles.length > 0 ? String.join(",", profiles) : "default";

        log.info("=== CV Mobile Startup Config ===");
        log.info("Profile: {}", profile);

        List<ProductionSetting> missing = new java.util.ArrayList<>();

        for (ProductionSetting setting : TRACKED_SETTINGS) {
            String value = configuration.value(setting);
            boolean present = value != null && !value.isBlank();

            if (present) {
                log.info("{} {} SET", setting.name(), padding(setting));
            } else {
                log.warn("{} {} MISSING", setting.name(), padding(setting));
                missing.add(setting);
            }
        }

        log.info("================================");

        if (missing.contains(ProductionSetting.DB_PASSWORD)) {
            throw new IllegalStateException(
                    "Invalid startup configuration for profile '" + profile
                            + "': [DB_PASSWORD]");
        }

        // Warnings actionnables en dev
        if (missing.contains(ProductionSetting.DEEPSEEK_API_KEY)) {
            log.warn("DeepSeek desactive (mode degrade). "
                    + "Ajoutez DEEPSEEK_API_KEY dans backend/.env ou exportez-la dans votre shell.");
        }
        if (missing.contains(ProductionSetting.GOOGLE_CLIENT_ID)) {
            log.warn("Connexion Google desactivee : configurez GOOGLE_CLIENT_ID.");
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

    private ProductionConfiguration snapshot() {
        EnumMap<ProductionSetting, String> values = new EnumMap<>(ProductionSetting.class);
        for (ProductionSetting setting : ProductionSetting.values()) {
            if (setting != ProductionSetting.ACTIVE_PROFILES) {
                values.put(setting, env.getProperty(setting.propertyName()));
            }
        }
        return new ProductionConfiguration(Set.of(env.getActiveProfiles()), values);
    }

    /** Aligne les cles pour que la banniere soit lisible. */
    private String padding(ProductionSetting setting) {
        int maxLen = TRACKED_SETTINGS.stream().map(Enum::name)
                .mapToInt(String::length).max().orElse(20);
        int dots = Math.max(3, maxLen - setting.name().length() + 3);
        return ".".repeat(dots);
    }
}
