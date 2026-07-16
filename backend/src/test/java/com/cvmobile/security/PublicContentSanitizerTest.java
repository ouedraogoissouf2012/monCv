package com.cvmobile.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class PublicContentSanitizerTest {
    private final PublicContentSanitizer sanitizer = new PublicContentSanitizer();

    @Test
    void removesControlAndBidirectionalOverrideCharacters() {
        assertThat(sanitizer.text("A\u0000B\u202EC\u2066D", 20)).isEqualTo("ABCD");
    }

    @Test
    void truncatesByCodePointWithoutSplittingUnicodePairs() {
        assertThat(sanitizer.text("A\uD83D\uDE80B", 2)).isEqualTo("A\uD83D\uDE80");
    }
}
