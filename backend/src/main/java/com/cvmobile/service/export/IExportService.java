package com.cvmobile.service.export;

import com.cvmobile.model.Cv;

import java.io.IOException;

/**
 * Contrat pour les services d'export de CV.
 * Chaque implementation genere un format different (PDF, DOCX...).
 */
public interface IExportService {

    byte[] generate(Cv cv) throws IOException;

    String getContentType();

    String getFileExtension();
}
