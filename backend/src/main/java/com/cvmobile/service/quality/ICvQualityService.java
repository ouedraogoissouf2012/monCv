package com.cvmobile.service.quality;

import java.util.List;

/**
 * Contrat pour le service de controle qualite du contenu CV.
 */
public interface ICvQualityService {

    String clean(String text);

    String removeRepeatedTitle(String description, String poste, String entreprise);
}
