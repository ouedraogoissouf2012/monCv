package com.cvmobile.service.ai;

import com.cvmobile.exception.ai.AiServiceException;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Deque;
import java.util.List;

/**
 * Fenetre bornee des derniers appels IA utilisee par l'endpoint de statut.
 */
@Component
public class AiTelemetry {

    private static final int MAX_SAMPLES = 100;

    private final Deque<Long> latencySamples = new ArrayDeque<>(MAX_SAMPLES);
    private LastError lastError;
    private boolean fallbackInUse;

    public synchronized void recordSuccess(long latencyMs, boolean fallback) {
        addLatency(latencyMs);
        fallbackInUse = fallback;
    }

    public synchronized void recordFailure(long latencyMs, AiServiceException error) {
        addLatency(latencyMs);
        recordLastError(error);
        fallbackInUse = false;
    }

    public synchronized void recordLastError(AiServiceException error) {
        lastError = new LastError(Instant.now(), error.getErrorCode());
    }

    public synchronized Snapshot snapshot() {
        List<Long> sorted = new ArrayList<>(latencySamples);
        Collections.sort(sorted);
        return new Snapshot(
                percentile(sorted, 0.50),
                percentile(sorted, 0.95),
                lastError,
                fallbackInUse,
                sorted.size());
    }

    private void addLatency(long latencyMs) {
        if (latencySamples.size() == MAX_SAMPLES) {
            latencySamples.removeFirst();
        }
        latencySamples.addLast(Math.max(0, latencyMs));
    }

    private long percentile(List<Long> sorted, double percentile) {
        if (sorted.isEmpty()) {
            return 0;
        }
        int index = Math.max(0, (int) Math.ceil(percentile * sorted.size()) - 1);
        return sorted.get(index);
    }

    public record LastError(Instant timestamp, String type) {}

    public record Snapshot(long latencyP50Ms, long latencyP95Ms,
                           LastError lastError, boolean fallbackInUse,
                           int sampleCount) {}
}
