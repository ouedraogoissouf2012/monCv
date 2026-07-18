package com.cvmobile.service.user;

import com.cvmobile.model.User;
import org.springframework.security.core.userdetails.UserDetailsService;

import java.util.Optional;

/**
 * Contrat pour le service utilisateur.
 * Etend UserDetailsService pour l'integration Spring Security.
 */
public interface IUserService extends UserDetailsService {

    User findById(Long id);

    User findByEmail(String email);

    Optional<User> findOptionalByEmail(String email);

    Optional<User> findByGoogleSubject(String googleSubject);

    User save(User user);

    boolean existsByEmail(String email);

    void deleteById(Long id);
}
