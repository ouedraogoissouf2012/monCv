package com.cvmobile.service.ai;

import java.util.Map;

/**
 * Contrat pour le service de generation de resume professionnel par IA.
 */
public interface IResumeGeneratorService {

    Map<String, String> generateResume(String titrePoste, String competences, String experience);
}
