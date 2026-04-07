package com.cvmobile.service.file;

import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Path;

/**
 * Contrat pour le service de stockage de fichiers.
 */
public interface IFileStorageService {

    String storePhoto(MultipartFile file);

    Path resolve(String filename);
}
