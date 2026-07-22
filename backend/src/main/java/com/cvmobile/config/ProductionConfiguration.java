package com.cvmobile.config;

import java.util.Collections;
import java.util.EnumMap;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

record ProductionConfiguration(
        Set<String> activeProfiles,
        Map<ProductionSetting, String> values
) {
    ProductionConfiguration {
        activeProfiles = Set.copyOf(Objects.requireNonNull(activeProfiles));
        EnumMap<ProductionSetting, String> copy = new EnumMap<>(ProductionSetting.class);
        copy.putAll(Objects.requireNonNull(values));
        values = Collections.unmodifiableMap(copy);
    }

    boolean isProduction() {
        return activeProfiles.contains("prod");
    }

    String value(ProductionSetting setting) {
        return values.get(setting);
    }
}
