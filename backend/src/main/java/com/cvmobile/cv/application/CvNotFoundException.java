package com.cvmobile.cv.application;

/**
 * Signale qu'aucun CV n'existe pour l'identifiant et le proprietaire demandes.
 *
 * <p>Exception d'application <em>pure</em> : elle ne depend d'aucun type web.
 * Un adaptateur entrant la traduit en reponse HTTP 404 (issue #255, ADR 003).
 */
public class CvNotFoundException extends RuntimeException {

    private final long cvId;

    public CvNotFoundException(long cvId) {
        super("CV non trouve avec id = " + cvId);
        this.cvId = cvId;
    }

    /** Identifiant du CV introuvable. */
    public long cvId() {
        return cvId;
    }
}
