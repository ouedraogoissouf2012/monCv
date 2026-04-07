package com.cvmobile.service;

import com.cvmobile.exception.FileStorageException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileStorageService implements com.cvmobile.service.file.IFileStorageService {

    private final Path uploadDir;

    public FileStorageService(@Value("${upload.dir:${user.home}/cv-uploads/photos}") String uploadDirStr) {
        this.uploadDir = Paths.get(uploadDirStr).toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.uploadDir);
        } catch (IOException e) {
            throw new FileStorageException("Impossible de creer le repertoire d'upload : " + uploadDirStr, e);
        }
    }

    /**
     * Sauvegarde un fichier image et retourne le chemin relatif de l'endpoint
     * qui le sert : /api/uploads/photos/{filename}
     */
    public String storePhoto(MultipartFile file) {
        String originalName = file.getOriginalFilename();
        String extension = "";
        if (originalName != null && originalName.contains(".")) {
            extension = originalName.substring(originalName.lastIndexOf('.'));
        }
        String filename = UUID.randomUUID() + extension;

        try {
            Path target = uploadDir.resolve(filename);
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new FileStorageException("Erreur lors de la sauvegarde du fichier", e);
        }

        return "/api/uploads/photos/" + filename;
    }

    public Path resolve(String filename) {
        return uploadDir.resolve(filename).normalize();
    }
}
