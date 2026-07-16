package com.cvmobile.service.file;

import com.cvmobile.exception.BusinessException;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Locale;
import java.util.Map;

@Component
public class ImageFileValidator {

    static final long MAX_SIZE = 2L * 1024 * 1024;
    private static final Map<String, String> MIME_BY_EXTENSION = Map.of(
            "jpg", "image/jpeg",
            "jpeg", "image/jpeg",
            "png", "image/png",
            "webp", "image/webp");

    public void validate(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            reject("FILE_EMPTY", "Le fichier est vide");
        }
        if (file.getSize() > MAX_SIZE) {
            reject("FILE_TOO_LARGE", "Le fichier depasse la taille maximale de 2 MB");
        }

        String extension = extensionOf(file.getOriginalFilename());
        String expectedMime = MIME_BY_EXTENSION.get(extension);
        String declaredMime = file.getContentType();
        if (expectedMime == null || declaredMime == null
                || !expectedMime.equals(declaredMime.toLowerCase(Locale.ROOT))) {
            reject("INVALID_FILE_TYPE", "Format image incoherent ou non autorise");
        }

        try {
            byte[] header = file.getInputStream().readNBytes(12);
            if (!matchesSignature(extension, header)) {
                reject("INVALID_FILE_SIGNATURE", "Le contenu ne correspond pas au format annonce");
            }
        } catch (IOException exception) {
            reject("INVALID_FILE_CONTENT", "Impossible de lire le fichier");
        }
    }

    private String extensionOf(String filename) {
        if (filename == null) return "";
        int dot = filename.lastIndexOf('.');
        return dot < 0 ? "" : filename.substring(dot + 1).toLowerCase(Locale.ROOT);
    }

    private boolean matchesSignature(String extension, byte[] bytes) {
        return switch (extension) {
            case "jpg", "jpeg" -> startsWith(bytes, 0xFF, 0xD8, 0xFF);
            case "png" -> startsWith(bytes, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A);
            case "webp" -> startsWith(bytes, 0x52, 0x49, 0x46, 0x46)
                    && bytes.length >= 12
                    && bytes[8] == 0x57 && bytes[9] == 0x45
                    && bytes[10] == 0x42 && bytes[11] == 0x50;
            default -> false;
        };
    }

    private boolean startsWith(byte[] actual, int... expected) {
        if (actual.length < expected.length) return false;
        for (int i = 0; i < expected.length; i++) {
            if (Byte.toUnsignedInt(actual[i]) != expected[i]) return false;
        }
        return true;
    }

    private void reject(String code, String message) {
        throw new BusinessException(code, message);
    }
}
