package com.cvmobile.service.auth;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.LoginRequest;
import com.cvmobile.dto.RegisterRequest;

/**
 * Contrat pour le service d'authentification.
 */
public interface IAuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse refreshToken(String refreshToken);
}
