package com.cvmobile.service.auth;

import com.cvmobile.exception.BusinessException;
import com.cvmobile.model.PasswordResetToken;
import com.cvmobile.model.User;
import com.cvmobile.repository.PasswordResetTokenRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.security.RateLimitService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.concurrent.RejectedExecutionException;

/**
 * Reinitialisation de mot de passe (issue #381).
 *
 * Securite (OWASP) : reponse uniforme a {@link #requestReset} (anti-enumeration
 * d'emails), jeton cryptographiquement aleatoire jamais persiste en clair (seule
 * son empreinte SHA-256 l'est), usage unique, duree de vie courte, rate-limiting
 * de la demande. Le jeton n'est jamais journalise.
 *
 * Anti-enumeration par timing (issue #495) : l'envoi de l'email est asynchrone et
 * declenche <strong>apres le commit</strong> de la transaction. Asynchrone, il sort
 * du chemin de reponse pour que la demande revienne en temps constant que l'email
 * existe ou non. Apres commit, il garantit que le jeton est deja persiste et donc
 * utilisable quand l'utilisateur clique le lien (aucune course entre l'envoi et le
 * commit qui rendrait {@link #resetPassword} incapable de retrouver le jeton).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private static final Duration TOKEN_TTL = Duration.ofMinutes(30);
    private static final int TOKEN_BYTES = 32;
    private static final long RATE_LIMIT_CAPACITY = 5;
    private static final Duration RATE_LIMIT_PERIOD = Duration.ofHours(1);
    private static final String INVALID_MESSAGE =
            "Lien de reinitialisation invalide ou expire";
    private static final String INVALID_CODE = "PASSWORD_RESET_TOKEN_INVALID";

    private final UserRepository users;
    private final PasswordResetTokenRepository tokens;
    private final PasswordEncoder passwordEncoder;
    private final PasswordResetEmailSender emailSender;
    private final RateLimitService rateLimit;

    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Demande un lien de reinitialisation. Ne revele jamais si l'email existe :
     * un email inconnu ou une limite de debit atteinte produisent le meme effet
     * observable (le controleur repond toujours 200).
     */
    @Transactional
    public void requestReset(String email) {
        if (!rateLimit.consume("password-reset:" + email,
                RATE_LIMIT_CAPACITY, RATE_LIMIT_PERIOD).allowed()) {
            return;
        }
        users.findByEmailIgnoreCase(email).ifPresent(user -> {
            String rawToken = generateToken();
            tokens.save(PasswordResetToken.builder()
                    .userId(user.getId())
                    .tokenHash(hash(rawToken))
                    .expiresAt(Instant.now().plus(TOKEN_TTL))
                    .build());
            sendResetLinkAfterCommit(email, rawToken);
            log.info("Jeton de reinitialisation emis pour userId={}", user.getId());
        });
    }

    /**
     * Programme l'envoi (asynchrone) du lien apres le commit de la transaction courante,
     * de sorte que le jeton soit deja persiste lorsque l'utilisateur clique le lien.
     * En l'absence de transaction active (ne devrait pas arriver, la methode est
     * {@code @Transactional}), l'envoi est declenche immediatement par prudence.
     */
    private void sendResetLinkAfterCommit(String email, String rawToken) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            dispatchEmail(email, rawToken);
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        dispatchEmail(email, rawToken);
                    }
                });
    }

    /**
     * Soumet l'envoi asynchrone en absorbant un eventuel rejet de l'executor (pool
     * sature, {@code AbortPolicy}). Le rejet ne doit jamais remonter au thread de
     * requete : cela romprait la reponse uniforme et le temps de reponse constant
     * (anti-enumeration). On journalise l'incident sans PII ni jeton (aucun email ici,
     * le sender se charge du log masque sur succes/echec d'envoi effectif).
     */
    private void dispatchEmail(String email, String rawToken) {
        try {
            emailSender.sendResetLink(email, rawToken);
        } catch (RejectedExecutionException rejected) {
            log.error("Envoi de reinitialisation rejete : executor d'emails sature");
        }
    }

    /**
     * Applique un nouveau mot de passe si le jeton est valide (existant, non
     * expire, non utilise), puis invalide le jeton. Leve une
     * {@link BusinessException} (400) sinon.
     */
    @Transactional
    public void resetPassword(String rawToken, String newPassword) {
        PasswordResetToken token = tokens.findByTokenHash(hash(rawToken))
                .filter(t -> t.getUsedAt() == null
                        && t.getExpiresAt().isAfter(Instant.now()))
                .orElseThrow(() -> new BusinessException(INVALID_CODE, INVALID_MESSAGE));

        User user = users.findById(token.getUserId())
                .orElseThrow(() -> new BusinessException(INVALID_CODE, INVALID_MESSAGE));

        user.setPassword(passwordEncoder.encode(newPassword));
        users.save(user);

        token.setUsedAt(Instant.now());
        tokens.save(token);
        log.info("Mot de passe reinitialise pour userId={}", user.getId());
    }

    private String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String rawToken) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 indisponible", exception);
        }
    }
}
