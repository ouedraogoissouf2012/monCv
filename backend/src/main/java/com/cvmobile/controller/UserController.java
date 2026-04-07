package com.cvmobile.controller;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.service.user.IUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
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

    @GetMapping("/me")
    @Operation(summary = "Obtenir le profil de l'utilisateur connecte")
    public ResponseEntity<AuthResponse.UserDto> getCurrentUser(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(userMapper.toUserDto(user));
    }

    @PutMapping("/me")
    @Operation(summary = "Mettre a jour le profil de l'utilisateur connecte")
    public ResponseEntity<AuthResponse.UserDto> updateCurrentUser(
            @AuthenticationPrincipal User user,
            @RequestBody Map<String, String> updates) {

        if (updates.containsKey("nom")) {
            user.setNom(updates.get("nom"));
        }
        if (updates.containsKey("prenom")) {
            user.setPrenom(updates.get("prenom"));
        }

        User updatedUser = userService.save(user);
        return ResponseEntity.ok(userMapper.toUserDto(updatedUser));
    }

    @DeleteMapping("/me")
    @Operation(summary = "Supprimer le compte de l'utilisateur connecte")
    public ResponseEntity<Void> deleteCurrentUser(@AuthenticationPrincipal User user) {
        userService.deleteById(user.getId());
        return ResponseEntity.noContent().build();
    }
}
