package com.cvmobile.observability;

import org.slf4j.MDC;

public final class CorrelationIdSupport {

    private CorrelationIdSupport() {
    }

    public static String current() {
        return MDC.get(CorrelationIdFilter.MDC_KEY);
    }
}
