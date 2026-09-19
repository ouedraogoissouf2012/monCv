package com.cvmobile.validation;

/**
 * Groupe de validation des contraintes propres au remplacement complet d'une
 * ressource (issue #537).
 *
 * <p>Un {@code PUT} remplace la ressource entiere : un corps incomplet est une
 * requete invalide, pas une demande de conservation partielle. Les contraintes
 * portant ce groupe ne s'appliquent donc <strong>qu'a la mise a jour</strong>,
 * jamais a la creation, ou les valeurs absentes recoivent leurs defauts.
 *
 * <p>Cote controleur, l'annotation doit citer <em>les deux</em> groupes :
 * {@code @Validated({Default.class, OnUpdate.class})}. Citer ce seul groupe
 * desactiverait silencieusement toutes les contraintes du groupe par defaut
 * ({@code @NotBlank} sur le titre, {@code @Size} sur les sections...).
 */
public interface OnUpdate {
}
