package com.cvmobile.controller;

import com.cvmobile.dto.NotificationDtos;
import com.cvmobile.model.User;
import com.cvmobile.service.notification.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/notifications") @RequiredArgsConstructor
public class NotificationController {
    private final NotificationService service;

    @PostMapping("/devices")
    public ResponseEntity<Void> register(@AuthenticationPrincipal User user,
            @Valid @RequestBody NotificationDtos.DeviceTokenRequest request) {
        service.registerDevice(user, request);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/devices")
    public ResponseEntity<Void> unregister(@AuthenticationPrincipal User user,
            @Valid @RequestBody NotificationDtos.TokenDeleteRequest request) {
        service.unregisterDevice(user, request.token());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/preferences")
    public NotificationDtos.Preferences preferences(@AuthenticationPrincipal User user) {
        return service.getPreferences(user);
    }

    @PutMapping("/preferences")
    public NotificationDtos.Preferences update(@AuthenticationPrincipal User user,
            @RequestBody NotificationDtos.Preferences request) {
        return service.updatePreferences(user, request);
    }
}
