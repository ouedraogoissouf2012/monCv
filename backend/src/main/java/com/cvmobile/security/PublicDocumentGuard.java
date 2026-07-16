package com.cvmobile.security;

import com.cvmobile.config.PublicPortfolioSecurityProperties;
import com.cvmobile.exception.PublicDocumentUnavailableException;
import org.springframework.stereotype.Component;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

@Component
public final class PublicDocumentGuard {
    private final Semaphore permits;
    private final long acquireTimeoutMillis;
    private final int maxDocumentBytes;

    public PublicDocumentGuard(PublicPortfolioSecurityProperties properties) {
        permits = new Semaphore(properties.maxConcurrentDocuments(), true);
        acquireTimeoutMillis = properties.documentAcquireTimeout().toMillis();
        maxDocumentBytes = properties.maxDocumentBytes();
    }

    public byte[] generate(Supplier<byte[]> generator) {
        boolean acquired = false;
        try {
            acquired = permits.tryAcquire(acquireTimeoutMillis, TimeUnit.MILLISECONDS);
            if (!acquired) {
                throw new PublicDocumentUnavailableException(
                        "Generation de document temporairement saturee");
            }
            byte[] document = generator.get();
            if (document == null || document.length == 0) {
                throw new PublicDocumentUnavailableException("Document genere invalide");
            }
            if (document.length > maxDocumentBytes) {
                throw new PublicDocumentUnavailableException(
                        "Document genere au-dessus de la taille autorisee");
            }
            return document;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new PublicDocumentUnavailableException(
                    "Generation de document interrompue");
        } finally {
            if (acquired) permits.release();
        }
    }
}
