package com.cvmobile.service;

import com.cvmobile.exception.FileStorageException;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.LinkOption;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
public class FileStorageService implements com.cvmobile.service.file.IFileStorageService {
    private static final Pattern PHOTO_FILENAME = Pattern.compile(
            "[0-9a-fA-F-]{36}\\.(?:jpe?g|png|webp)", Pattern.CASE_INSENSITIVE);

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
        return storePhotoWithMetadata(file).url();
    }

    public StoredUpload storePhotoWithMetadata(MultipartFile file) {
        String originalName = file.getOriginalFilename();
        String extension = "";
        if (originalName != null && originalName.contains(".")) {
            extension = originalName.substring(originalName.lastIndexOf('.'))
                    .toLowerCase(Locale.ROOT);
        }
        if (!extension.matches("\\.(?:jpe?g|png|webp)")) {
            throw new FileStorageException("Extension de photo invalide");
        }
        String filename = UUID.randomUUID() + extension;

        Path target = uploadDir.resolve(filename);
        try (InputStream input = file.getInputStream()) {
            Files.copy(input, target);
        } catch (IOException e) {
            deleteQuietly(target);
            throw new FileStorageException("Erreur lors de la sauvegarde du fichier", e);
        }

        return new StoredUpload(filename, "/api/uploads/photos/" + filename);
    }

    public Path resolve(String filename) {
        return uploadDir.resolve(filename).normalize();
    }

    public Optional<StoredPhoto> loadPhoto(String filename) {
        if (filename == null || !PHOTO_FILENAME.matcher(filename).matches()) {
            return Optional.empty();
        }
        Path path = resolve(filename);
        if (!path.getParent().equals(uploadDir)
                || !Files.isRegularFile(path, LinkOption.NOFOLLOW_LINKS)
                || !Files.isReadable(path)) {
            return Optional.empty();
        }
        try {
            return Optional.of(new StoredPhoto(
                    new UrlResource(path.toUri()), contentType(filename), Files.size(path)));
        } catch (IOException exception) {
            return Optional.empty();
        }
    }

    public void deletePhoto(String filename) {
        if (filename == null || !PHOTO_FILENAME.matcher(filename).matches()) return;
        Path path = resolve(filename);
        if (!path.getParent().equals(uploadDir)) return;
        try {
            Files.deleteIfExists(path);
        } catch (IOException exception) {
            throw new FileStorageException("Impossible de supprimer la photo", exception);
        }
    }

    private void deleteQuietly(Path path) {
        try {
            Files.deleteIfExists(path);
        } catch (IOException ignored) {
            // L'erreur de stockage initiale reste la cause utile.
        }
    }

    private String contentType(String filename) {
        String lower = filename.toLowerCase(Locale.ROOT);
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".webp")) return "image/webp";
        return "image/jpeg";
    }

    public record StoredPhoto(Resource resource, String contentType, long contentLength) {
    }

    public record StoredUpload(String filename, String url) {
    }
}
