package com.cvmobile.controller;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.UpdateProfileRequest;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.service.cv.ICvService;
import com.cvmobile.service.user.IUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@Tag(name = "Utilisateurs", description = "Gestion des utilisateurs")
@SecurityRequirement(name = "bearerAuth")
public class UserController {

    private final IUserService userService;
    private final UserMapper userMapper;
    private final ICvService cvService;

    @GetMapping("/me")
    @Operation(summary = "Obtenir le profil de l'utilisateur connecte")
    public ResponseEntity<AuthResponse.UserDto> getCurrentUser(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(userMapper.toUserDto(user));
    }

    @PutMapping("/me")
    @Operation(summary = "Mettre a jour le profil de l'utilisateur connecte")
    public ResponseEntity<AuthResponse.UserDto> updateCurrentUser(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody UpdateProfileRequest request) {

        // Mise a jour partielle : un champ null reste inchange (comportement
        // preserve depuis l'ancien Map). Les valeurs fournies sont bornees a
        // 100 caracteres (@Size sur le DTO), plus de mass-assignment non type.
        if (request.getNom() != null) {
            user.setNom(request.getNom());
        }
        if (request.getPrenom() != null) {
            user.setPrenom(request.getPrenom());
        }

        User updatedUser = userService.save(user);
        return ResponseEntity.ok(userMapper.toUserDto(updatedUser));
    }

    @GetMapping("/me/export")
    @Operation(summary = "Exporter les donnees personnelles et CV de l'utilisateur connecte")
    public ResponseEntity<Map<String, Object>> exportCurrentUser(@AuthenticationPrincipal User user) {
        AuthResponse.UserDto profile = userMapper.toUserDto(user);
        java.util.List<CvResponse> cvs = cvService.getAllCvsByUserId(user.getId());

        return ResponseEntity.ok(Map.of(
                "profile", profile,
                "cvs", cvs,
                "cvCount", cvs.size(),
                "exportedAt", java.time.OffsetDateTime.now().toString(),
                "notice", "Export JSON des donnees MonCV rattachees au compte connecte."));
    }

    @DeleteMapping("/me")
    @Operation(summary = "Supprimer le compte de l'utilisateur connecte")
    public ResponseEntity<Void> deleteCurrentUser(@AuthenticationPrincipal User user) {
        userService.deleteById(user.getId());
        return ResponseEntity.noContent().build();
    }
}
