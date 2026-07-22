package com.cvmobile.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.PropertySourcesPropertyResolver;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

class ProductionShutdownConfigurationTest {

    @Test
    void productionDrainsRequestsBeforeContainerShutdown() throws IOException {
        var resources = new YamlPropertySourceLoader()
                .load("production", new ClassPathResource("application-prod.yml"));
        var propertySources = new MutablePropertySources();
        resources.forEach(propertySources::addLast);
        var properties = new PropertySourcesPropertyResolver(propertySources);

        assertThat(properties.getProperty("server.shutdown"))
                .isEqualTo("graceful");
        assertThat(properties.getProperty("spring.lifecycle.timeout-per-shutdown-phase"))
                .isEqualTo("30s");
    }
}
