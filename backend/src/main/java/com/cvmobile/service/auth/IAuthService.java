package com.cvmobile.service.auth;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.LoginRequest;
import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.model.User;

/**
 * Contrat pour le service d'authentification.
 */
public interface IAuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse loginWithGoogle(String credential);

    AuthResponse linkGoogle(User user, String credential);

    AuthResponse refreshToken(String refreshToken);
}
