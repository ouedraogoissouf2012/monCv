package com.cvmobile.service.user;

import com.cvmobile.model.User;
import org.springframework.security.core.userdetails.UserDetailsService;

/**
 * Contrat pour le service utilisateur.
 * Etend UserDetailsService pour l'integration Spring Security.
 */
public interface IUserService extends UserDetailsService {

    User findById(Long id);

    User findByEmail(String email);

    User save(User user);

    boolean existsByEmail(String email);

    void deleteById(Long id);
}
