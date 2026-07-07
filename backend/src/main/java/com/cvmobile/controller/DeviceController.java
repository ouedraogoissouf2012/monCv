package com.cvmobile.controller;

import com.cvmobile.dto.DeviceTokenRequest;
import com.cvmobile.model.DeviceToken;
import com.cvmobile.model.User;
import com.cvmobile.repository.DeviceTokenRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@Tag(name = "Devices", description = "Gestion des tokens de notification push")
@SecurityRequirement(name = "bearerAuth")
public class DeviceController {

    private final DeviceTokenRepository deviceTokenRepository;

    @PostMapping("/register")
    @Operation(summary = "Enregistrer un token FCM pour les notifications push")
    public ResponseEntity<Void> registerToken(
            @Valid @RequestBody DeviceTokenRequest request,
            @AuthenticationPrincipal User user) {
        // Si le token existe deja, mettre a jour le user (peut changer d'appareil)
        var existing = deviceTokenRepository.findByToken(request.getToken());
        if (existing.isPresent()) {
            var dt = existing.get();
            dt.setUser(user);
            dt.setPlatform(request.getPlatform() != null ? request.getPlatform() : "ANDROID");
            deviceTokenRepository.save(dt);
            log.info("Device token mis a jour: userId={}", user.getId());
        } else {
            deviceTokenRepository.save(DeviceToken.builder()
                    .user(user)
                    .token(request.getToken())
                    .platform(request.getPlatform() != null ? request.getPlatform() : "ANDROID")
                    .build());
            log.info("Device token enregistre: userId={}", user.getId());
        }
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/unregister")
    @Transactional
    @Operation(summary = "Supprimer un token FCM (deconnexion, desinstallation)")
    public ResponseEntity<Void> unregisterToken(@RequestParam String token) {
        deviceTokenRepository.deleteByToken(token);
        log.info("Device token supprime");
        return ResponseEntity.noContent().build();
    }
}
