package com.cvmobile.web;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageRequest;

class PageLimitsTest {

    @Test
    void plafonneLaTailleA100() {
        assertThat(PageLimits.cap(PageRequest.of(0, 500)).getPageSize()).isEqualTo(100);
        assertThat(PageLimits.cap(PageRequest.of(2, 10)).getPageNumber()).isEqualTo(2);
    }
}
