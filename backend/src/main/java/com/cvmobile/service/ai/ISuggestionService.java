package com.cvmobile.service.ai;

import com.cvmobile.dto.SuggestResponse;

/**
 * Contrat pour le service de suggestions de bullet points.
 */
public interface ISuggestionService {

    SuggestResponse generateSuggestions(String poste, String entreprise);
}
