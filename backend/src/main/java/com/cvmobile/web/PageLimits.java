package com.cvmobile.web;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

/**
 * Plafond des listes API (issue #510).
 */
public final class PageLimits {

    public static final int DEFAULT = 50;
    public static final int MAX = 100;

    private PageLimits() {
    }

    public static Pageable cap(Pageable pageable) {
        if (pageable == null || pageable.isUnpaged()) {
            return PageRequest.of(0, DEFAULT);
        }
        int size = Math.min(Math.max(pageable.getPageSize(), 1), MAX);
        int page = Math.max(pageable.getPageNumber(), 0);
        return PageRequest.of(page, size, pageable.getSort());
    }
}
