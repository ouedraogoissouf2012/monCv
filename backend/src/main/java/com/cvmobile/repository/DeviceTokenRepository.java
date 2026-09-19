package com.cvmobile.repository;
import com.cvmobile.model.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.*;
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByToken(String token);
    List<DeviceToken> findByUserId(Long userId);
    void deleteByTokenAndUserId(String token, Long userId);

    /**
     * Enregistre un jeton d'appareil, ou le rattache au compte courant s'il
     * existe deja (issue #511).
     *
     * <p>Remplace un cycle lecture-puis-ecriture qui laissait passer une course :
     * deux requetes concurrentes portant le meme jeton — l'application le
     * reenregistre au demarrage, et Firebase peut le renouveler au meme moment —
     * ne trouvaient ni l'une ni l'autre de ligne existante, tentaient toutes deux
     * l'insertion, et la seconde violait la contrainte d'unicite sur {@code token}.
     * L'utilisateur recevait une 500 pour une operation pourtant idempotente.
     *
     * <p>{@code ON CONFLICT} rend l'operation atomique cote base : il n'existe
     * plus d'intervalle entre le constat et l'ecriture. Un jeton migrant d'un
     * compte a l'autre — appareil partage, reinstallation — est reaffecte plutot
     * que duplique.
     *
     * <p>Les horodatages sont poses explicitement : une requete native ne
     * declenche pas les callbacks {@code @PrePersist} / {@code @PreUpdate} de
     * l'entite.
     */
    @Modifying
    @Query(value = """
            INSERT INTO device_tokens (user_id, token, platform, created_at, updated_at)
            VALUES (:userId, :token, :platform, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT (token) DO UPDATE
               SET user_id = EXCLUDED.user_id,
                   platform = EXCLUDED.platform,
                   updated_at = CURRENT_TIMESTAMP
            """, nativeQuery = true)
    void upsertToken(@Param("userId") Long userId,
                     @Param("token") String token,
                     @Param("platform") String platform);
}
