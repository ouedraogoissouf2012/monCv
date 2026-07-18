package com.cvmobile.controller;

import com.cvmobile.model.User;
import com.cvmobile.service.FileStorageService;
import com.cvmobile.service.PhotoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/uploads")
@RequiredArgsConstructor
@Tag(name = "Uploads", description = "Gestion des fichiers uploades")
public class UploadController {

    private final PhotoService photoService;

    @PostMapping(value = "/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Uploader une photo de profil")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<Map<String, String>> uploadPhoto(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal User user) {

        String url = photoService.upload(file, user);
        log.info("Photo de profil uploadee");
        return ResponseEntity.ok(Map.of("url", url));
    }

    @GetMapping("/photos/{filename:.+}")
    @Operation(summary = "Servir une photo appartenant a l'utilisateur connecte")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<Resource> servePhoto(
            @PathVariable String filename,
            @AuthenticationPrincipal User user) {
        FileStorageService.StoredPhoto photo = photoService.loadOwned(filename, user.getId());
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                .header(HttpHeaders.CACHE_CONTROL, "private, no-store")
                .header(HttpHeaders.VARY, HttpHeaders.AUTHORIZATION)
                .header("X-Content-Type-Options", "nosniff")
                .contentLength(photo.contentLength())
                .contentType(MediaType.parseMediaType(photo.contentType()))
                .body(photo.resource());
    }
}
