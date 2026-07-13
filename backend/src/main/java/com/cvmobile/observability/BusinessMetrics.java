package com.cvmobile.observability;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Component;

import java.util.concurrent.Callable;

@Component
public class BusinessMetrics {

    private final MeterRegistry meterRegistry;

    public BusinessMetrics(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    public void recordCvCreated(String template) {
        meterRegistry.counter("cv.created.total",
                "template", sanitize(template, "default")).increment();
    }

    public void recordImport(String format, boolean success) {
        meterRegistry.counter("import.cv.total",
                "format", sanitize(format, "unknown"),
                "success", Boolean.toString(success)).increment();
    }

    public <T> T recordPdfGeneration(String template, Callable<T> action) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            T result = action.call();
            sample.stop(meterRegistry.timer("pdf.generation.duration",
                    "template", sanitize(template, "unknown"),
                    "status", "success"));
            return result;
        } catch (Exception e) {
            sample.stop(meterRegistry.timer("pdf.generation.duration",
                    "template", sanitize(template, "unknown"),
                    "status", "error"));
            if (e instanceof RuntimeException runtimeException) {
                throw runtimeException;
            }
            throw new IllegalStateException(e);
        }
    }

    public void recordAiCall(String provider, String operation, String status) {
        meterRegistry.counter("ai.calls.total",
                "provider", sanitize(provider, "unknown"),
                "operation", sanitize(operation, "complete"),
                "status", sanitize(status, "unknown")).increment();
    }

    public void recordAiFallback(String primary, String fallback, String operation) {
        meterRegistry.counter("ai.fallback.triggered.total",
                "primary", sanitize(primary, "unknown"),
                "fallback", sanitize(fallback, "unknown"),
                "operation", sanitize(operation, "complete")).increment();
    }

    private String sanitize(String value, String fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        return value;
    }
}
