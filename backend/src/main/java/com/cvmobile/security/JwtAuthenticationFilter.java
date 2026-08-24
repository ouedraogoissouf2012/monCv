package com.cvmobile.security;

import com.cvmobile.model.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String token = getTokenFromRequest(request);

        if (StringUtils.hasText(token) && jwtTokenProvider.validateAccessToken(token)) {
            String email = jwtTokenProvider.getEmailFromToken(token);
            try {
                authenticate(request, userDetailsService.loadUserByUsername(email), token);
            } catch (UsernameNotFoundException ignored) {
                // Un JWT peut survivre a la suppression de son utilisateur dans
                // le stockage local du navigateur. Le traiter comme anonyme permet
                // aux routes publiques de rester accessibles; Spring Security
                // renverra ensuite 401 pour toute route protegee.
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Peuple le contexte de securite seulement si le jeton appartient encore a la
     * generation de sessions courante du compte (issue #505) : un access token emis
     * avant une deconnexion ou une reinitialisation de mot de passe est traite comme
     * anonyme, et Spring Security repondra 401 sur toute route protegee.
     *
     * <p>La generation n'est lisible que sur le {@link User} du domaine. Un principal
     * d'un autre type ne permettant aucune verification, il est refuse (fail-closed)
     * plutot qu'authentifie sans controle de revocation.
     */
    private void authenticate(HttpServletRequest request, UserDetails userDetails, String token) {
        if (!(userDetails instanceof User user)
                || !jwtTokenProvider.matchesTokenVersion(token, user.getTokenVersion())) {
            SecurityContextHolder.clearContext();
            return;
        }

        UsernamePasswordAuthenticationToken authenticationToken =
                new UsernamePasswordAuthenticationToken(
                        user,
                        null,
                        user.getAuthorities()
                );

        authenticationToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
        SecurityContextHolder.getContext().setAuthentication(authenticationToken);
    }

    private String getTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");

        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }

        return null;
    }
}
