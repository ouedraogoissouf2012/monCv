package com.cvmobile.service.ai;

import com.cvmobile.dto.EnhanceCvResponse;

/**
 * Contrat pour le service d'amelioration de CV par IA.
 * Niveaux: LITE (orthographe), MEDIUM (reformulation), MAX (ATS complet).
 */
public interface IEnhancementService {

    EnhanceCvResponse enhanceCv(Long cvId, Long userId, String level);

    EnhanceCvResponse adaptCvToJob(Long cvId, Long userId, String jobDescription);
}
