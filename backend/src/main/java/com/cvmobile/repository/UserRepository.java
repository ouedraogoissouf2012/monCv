package com.cvmobile.repository;

import com.cvmobile.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    /** Recherche insensible a la casse : l'email est un identifiant unique quelle
     * que soit la casse saisie (M-10). Couvre aussi les comptes existants stockes
     * en casse mixte. */
    Optional<User> findByEmailIgnoreCase(String email);

    Optional<User> findByGoogleSubject(String googleSubject);

    boolean existsByEmail(String email);

    boolean existsByEmailIgnoreCase(String email);
}
