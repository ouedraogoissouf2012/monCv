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
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService implements IAuthService {

    private final IUserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final UserMapper userMapper;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    public AuthResponse register(RegisterRequest request) {
        if (userService.existsByEmail(request.getEmail())) {
            throw new DuplicateEmailException(request.getEmail());
        }

        User user = userMapper.toUser(request);
        user.setPassword(passwordEncoder.encode(request.getPassword()));

        user = userService.save(user);

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

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) {
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
