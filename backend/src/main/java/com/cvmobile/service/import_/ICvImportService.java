package com.cvmobile.service.import_;

import com.cvmobile.dto.CvRequest;
import org.springframework.web.multipart.MultipartFile;

/**
 * Contrat pour le service d'import de CV depuis un fichier PDF/DOCX.
 */
public interface ICvImportService {

    CvRequest importCv(MultipartFile file);
}
