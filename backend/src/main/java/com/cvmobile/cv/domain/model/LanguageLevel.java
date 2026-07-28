package com.cvmobile.cv.domain.model;

/**
 * Niveau de maitrise d'une langue selon le CECRL, plus le niveau {@code NATIF}
 * pour la langue maternelle.
 *
 * <p>Type de domaine pur : il remplace l'enumeration jadis imbriquee dans
 * l'entite JPA {@code Language}, sans dependance a la persistance.
 */
public enum LanguageLevel {
    A1, A2, B1, B2, C1, C2, NATIF
}
