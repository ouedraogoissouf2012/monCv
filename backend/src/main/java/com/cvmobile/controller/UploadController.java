package com.cvmobile.controller;

import com.cvmobile.exception.BusinessException;
import com.cvmobile.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.net.MalformedURLException;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;

@Slf4j
@RestController
@RequestMapping("/api/uploads")
@RequiredArgsConstructor
@Tag(name = "Uploads", description = "Gestion des fichiers uploades")
public class UploadController {

    private final FileStorageService fileStorageService;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp");
    private static final Set<String> ALLOWED_MIME_TYPES = Set.of(
            "image/jpeg", "image/png", "image/webp"
    );
    private static final long MAX_SIZE = 2 * 1024 * 1024; // 2 MB

    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Uploader une photo de profil")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<Map<String, String>> uploadPhoto(
            @RequestParam("file") MultipartFile file) {

        // Validation fichier vide
        if (file.isEmpty()) {
            throw new BusinessException("FILE_EMPTY", "Le fichier est vide");
        }

        // Validation taille
        if (file.getSize() > MAX_SIZE) {
            throw new BusinessException("FILE_TOO_LARGE",
                    "Le fichier depasse la taille maximale de 2 MB");
        }

        // Validation MIME type
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType.toLowerCase())) {
            throw new BusinessException("INVALID_FILE_TYPE",
                    "Type de fichier non autorise. Formats acceptes: JPG, PNG, WebP");
        }

        // Validation extension
        String originalName = file.getOriginalFilename();
        if (originalName != null) {
            String ext = originalName.substring(originalName.lastIndexOf('.') + 1).toLowerCase();
            if (!ALLOWED_EXTENSIONS.contains(ext)) {
                throw new BusinessException("INVALID_FILE_EXTENSION",
                        "Extension non autorisee. Formats acceptes: .jpg, .png, .webp");
            }
        }

        String url = fileStorageService.storePhoto(file);
        log.info("Photo uploadee: {}", url);
        return ResponseEntity.ok(Map.of("url", url));
    }

    @GetMapping("/photos/{filename:.+}")
    @Operation(summary = "Servir une photo uploadee (acces public)")
    public ResponseEntity<Resource> servePhoto(@PathVariable String filename) {
        // Securite: empecher le path traversal
        if (filename.contains("..") || filename.contains("/") || filename.contains("\\")) {
            return ResponseEntity.badRequest().build();
        }

        try {
            Path filePath = fileStorageService.resolve(filename);
            Resource resource = new UrlResource(filePath.toUri());

            if (!resource.exists() || !resource.isReadable()) {
                return ResponseEntity.notFound().build();
            }

            String ct = determineContentType(filename);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                    .header(HttpHeaders.CACHE_CONTROL, "public, max-age=86400")
                    .contentType(MediaType.parseMediaType(ct))
                    .body(resource);
        } catch (MalformedURLException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    private String determineContentType(String filename) {
        String lower = filename.toLowerCase();
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".webp")) return "image/webp";
        return "image/jpeg";
    }
}
