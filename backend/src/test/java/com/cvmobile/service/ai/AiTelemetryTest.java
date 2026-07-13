package com.cvmobile.service.ai;

import com.cvmobile.exception.ai.AiProviderDownException;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AiTelemetryTest {

    @Test
    void keepsLastHundredSamplesAndComputesPercentiles() {
        AiTelemetry telemetry = new AiTelemetry();
        for (int latency = 1; latency <= 120; latency++) {
            telemetry.recordSuccess(latency, latency == 120);
        }
        telemetry.recordLastError(
                new AiProviderDownException("deepseek", "HTTP 503", null));

        AiTelemetry.Snapshot snapshot = telemetry.snapshot();

        assertThat(snapshot.sampleCount()).isEqualTo(100);
        assertThat(snapshot.latencyP50Ms()).isEqualTo(70);
        assertThat(snapshot.latencyP95Ms()).isEqualTo(115);
        assertThat(snapshot.fallbackInUse()).isTrue();
        assertThat(snapshot.lastError().type()).isEqualTo("AI_PROVIDER_DOWN");
        assertThat(snapshot.lastError().timestamp()).isNotNull();
    }
}
