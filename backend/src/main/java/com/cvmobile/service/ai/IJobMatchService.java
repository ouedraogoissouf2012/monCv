package com.cvmobile.service.ai;

import com.cvmobile.dto.JobMatchResponse;

/**
 * Contrat pour le service d'analyse de correspondance CV / offre d'emploi.
 */
public interface IJobMatchService {

    JobMatchResponse matchJob(Long cvId, String jobDescription);
}
