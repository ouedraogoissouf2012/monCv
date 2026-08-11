package com.cvmobile.service;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.LoginRequest;
import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.exception.DuplicateEmailException;
import com.cvmobile.exception.InvalidTokenException;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.security.JwtTokenProvider;
import com.cvmobile.service.auth.IAuthService;
import com.cvmobile.service.auth.GoogleIdentity;
import com.cvmobile.service.auth.GoogleIdentityVerifier;
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;

import java.util.Locale;

@Service
@RequiredArgsConstructor
public class AuthService implements IAuthService {

    private final IUserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final UserMapper userMapper;
    private final GoogleIdentityVerifier googleIdentityVerifier;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());
        if (userService.existsByEmail(email)) {
            throw new DuplicateEmailException(email);
        }

        User user = userMapper.toUser(request);
        user.setEmail(email); // stockage canonique en minuscules (M-10)
        user.setPassword(passwordEncoder.encode(request.getPassword()));

        try {
            user = userService.save(user);
        } catch (DataIntegrityViolationException exception) {
            // Le controle preliminaire est ergonomique, mais seule la contrainte
            // UNIQUE en base ferme la fenetre de course entre deux inscriptions.
            throw new DuplicateEmailException(request.getEmail());
        }

        String accessToken = jwtTokenProvider.generateToken(user.getEmail());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());

        return buildAuthResponse(user, accessToken, refreshToken);
    }

    public AuthResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        User user = (User) authentication.getPrincipal();

        String accessToken = jwtTokenProvider.generateToken(authentication);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getEmail());

        return buildAuthResponse(user, accessToken, refreshToken);
    }

    @Override
    public AuthResponse loginWithGoogle(String credential) {
        GoogleIdentity identity = googleIdentityVerifier.verify(credential);
        User user = userService.findByGoogleSubject(identity.subject())
                .orElseGet(() -> createGoogleUser(identity));
        return issueTokens(user);
    }

    @Override
    public AuthResponse linkGoogle(User currentUser, String credential) {
        GoogleIdentity identity = googleIdentityVerifier.verify(credential);
        if (!currentUser.getEmail().equalsIgnoreCase(identity.email())) {
            throw new com.cvmobile.exception.GoogleAuthException(
                    "GOOGLE_EMAIL_MISMATCH", "Le compte Google doit utiliser la meme adresse email");
        }
        userService.findByGoogleSubject(identity.subject())
                .filter(other -> !other.getId().equals(currentUser.getId()))
                .ifPresent(other -> { throw new com.cvmobile.exception.GoogleAuthException(
                        "GOOGLE_ACCOUNT_ALREADY_LINKED", "Ce compte Google est deja associe"); });
        currentUser.setGoogleSubject(identity.subject());
        currentUser.setPictureUrl(identity.pictureUrl());
        currentUser.setAuthProvider(User.AuthProvider.BOTH);
        return issueTokens(userService.save(currentUser));
    }

    /** Canonicalise un email (unicite insensible a la casse, coherente entre
     * inscription classique et Google — M-10). */
    private static String normalizeEmail(String email) {
        return email == null ? null : email.strip().toLowerCase(Locale.ROOT);
    }

    private User createGoogleUser(GoogleIdentity identity) {
        String email = normalizeEmail(identity.email());
        if (userService.findOptionalByEmail(email).isPresent()) {
            throw new com.cvmobile.exception.GoogleAuthException(
                    "GOOGLE_LINK_REQUIRED",
                    "Un compte existe deja avec cet email. Connectez-vous puis associez Google depuis le profil.");
        }
        User user = User.builder()
                .email(email)
                .password(null)
                .prenom(identity.givenName())
                .nom(identity.familyName())
                .googleSubject(identity.subject())
                .pictureUrl(identity.pictureUrl())
                .authProvider(User.AuthProvider.GOOGLE)
                .build();
        try {
            return userService.save(user);
        } catch (DataIntegrityViolationException exception) {
            return userService.findByGoogleSubject(identity.subject())
                    .orElseThrow(() -> new com.cvmobile.exception.GoogleAuthException(
                            "GOOGLE_ACCOUNT_CONFLICT", "Impossible de creer le compte Google"));
        }
    }

    private AuthResponse issueTokens(User user) {
        return buildAuthResponse(
                user,
                jwtTokenProvider.generateToken(user.getEmail()),
                jwtTokenProvider.generateRefreshToken(user.getEmail()));
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtTokenProvider.validateRefreshToken(refreshToken)) {
            throw new InvalidTokenException("Token de rafraichissement invalide");
        }

        String email = jwtTokenProvider.getEmailFromToken(refreshToken);
        User user = userService.findByEmail(email);

        String newAccessToken = jwtTokenProvider.generateToken(email);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(email);

        return buildAuthResponse(user, newAccessToken, newRefreshToken);
    }

    private AuthResponse buildAuthResponse(User user, String accessToken, String refreshToken) {
        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .user(userMapper.toUserDto(user))
                .build();
    }
}
