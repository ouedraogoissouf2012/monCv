package com.cvmobile.service.auth;

import com.cvmobile.exception.BusinessException;
import com.cvmobile.model.PasswordResetToken;
import com.cvmobile.model.User;
import com.cvmobile.repository.PasswordResetTokenRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.security.RateLimitResult;
import com.cvmobile.security.RateLimitService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.RejectedExecutionException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PasswordResetServiceTest {

    @Mock UserRepository users;
    @Mock PasswordResetTokenRepository tokens;
    @Mock PasswordEncoder passwordEncoder;
    @Mock PasswordResetEmailSender emailSender;
    @Mock RateLimitService rateLimit;
    @InjectMocks PasswordResetService service;

    @AfterEach
    void clearSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    private void allowRate() {
        when(rateLimit.consume(anyString(), anyLong(), any()))
                .thenReturn(RateLimitResult.allowed(4));
    }

    @Test
    void requestReset_emailConnu_persisteUnJetonHasheEtEnvoieLEmail() {
        allowRate();
        User user = User.builder().id(4L).email("a@b.c").build();
        when(users.findByEmail("a@b.c")).thenReturn(Optional.of(user));

        service.requestReset("a@b.c");

        verify(tokens).save(argThat(t ->
                t.getUserId().equals(4L)
                        && t.getTokenHash() != null && t.getTokenHash().length() == 64
                        && t.getUsedAt() == null
                        && t.getExpiresAt().isAfter(Instant.now())));
        verify(emailSender).sendResetLink(eq("a@b.c"), anyString());
    }

    @Test
    void requestReset_emailInconnu_neFuitePasEtNePersisteRien() {
        allowRate();
        when(users.findByEmail("absent@b.c")).thenReturn(Optional.empty());

        service.requestReset("absent@b.c");

        verify(tokens, never()).save(any());
        verifyNoInteractions(emailSender);
    }

    @Test
    void requestReset_transactionActive_neDeclencheLEnvoiQuApresLeCommit() {
        // Simule le contexte transactionnel de production : Spring enregistre des
        // synchronisations, l'envoi ne doit partir qu'au afterCommit (issue #495, piege
        // de course commit/envoi). Prouve aussi que l'envoi est hors du chemin de reponse :
        // requestReset revient sans avoir declenche l'envoi.
        TransactionSynchronizationManager.initSynchronization();
        allowRate();
        User user = User.builder().id(4L).email("a@b.c").build();
        when(users.findByEmail("a@b.c")).thenReturn(Optional.of(user));

        service.requestReset("a@b.c");

        // Le jeton est persiste, mais l'envoi n'a PAS encore eu lieu au retour de la methode.
        verify(tokens).save(any());
        verifyNoInteractions(emailSender);

        // Le commit declenche l'envoi (afterCommit), et seulement alors.
        List<TransactionSynchronization> syncs =
                TransactionSynchronizationManager.getSynchronizations();
        assertThat(syncs).hasSize(1);
        syncs.forEach(TransactionSynchronization::afterCommit);

        verify(emailSender).sendResetLink(eq("a@b.c"), anyString());
    }

    @Test
    void requestReset_transactionRollback_naEnvoieAucunEmail() {
        // Si la transaction n'aboutit pas (afterCommit jamais appele), aucun email ne part :
        // pas de lien vers un jeton qui n'a pas ete persiste.
        TransactionSynchronizationManager.initSynchronization();
        allowRate();
        User user = User.builder().id(4L).email("a@b.c").build();
        when(users.findByEmail("a@b.c")).thenReturn(Optional.of(user));

        service.requestReset("a@b.c");

        // On ne declenche jamais afterCommit (simulant un rollback).
        verifyNoInteractions(emailSender);
    }

    @Test
    void requestReset_executorSature_absorbeLeRejetSansPropager() {
        // Sans synchronisation active, l'envoi passe par le chemin direct ; un rejet de
        // l'executor (@Async + AbortPolicy) ne doit jamais remonter et rompre la reponse
        // uniforme / le temps constant.
        allowRate();
        User user = User.builder().id(4L).email("a@b.c").build();
        when(users.findByEmail("a@b.c")).thenReturn(Optional.of(user));
        doThrow(new RejectedExecutionException("pool sature"))
                .when(emailSender).sendResetLink(eq("a@b.c"), anyString());

        assertThatCode(() -> service.requestReset("a@b.c")).doesNotThrowAnyException();

        verify(tokens).save(any());
    }

    @Test
    void requestReset_limiteDeDebitAtteinte_neFaitRien() {
        when(rateLimit.consume(anyString(), anyLong(), any()))
                .thenReturn(RateLimitResult.rejected(Duration.ofMinutes(10)));

        service.requestReset("a@b.c");

        verifyNoInteractions(users, tokens, emailSender);
    }

    @Test
    void resetPassword_jetonValide_metAJourLeHashEtInvalideLeJeton() {
        User user = User.builder().id(4L).password("ancien").build();
        PasswordResetToken token = PasswordResetToken.builder().userId(4L)
                .expiresAt(Instant.now().plus(Duration.ofMinutes(10))).build();
        when(tokens.findByTokenHash(anyString())).thenReturn(Optional.of(token));
        when(users.findById(4L)).thenReturn(Optional.of(user));
        when(passwordEncoder.encode("NouveauMotDePasse1")).thenReturn("hash-bcrypt");

        service.resetPassword("raw-token", "NouveauMotDePasse1");

        assertThat(user.getPassword()).isEqualTo("hash-bcrypt");
        assertThat(token.getUsedAt()).isNotNull();
        verify(users).save(user);
        verify(tokens).save(token);
    }

    @Test
    void resetPassword_jetonExpire_estRejete() {
        PasswordResetToken expired = PasswordResetToken.builder().userId(4L)
                .expiresAt(Instant.now().minus(Duration.ofMinutes(1))).build();
        when(tokens.findByTokenHash(anyString())).thenReturn(Optional.of(expired));

        assertThatThrownBy(() -> service.resetPassword("raw", "NouveauMotDePasse1"))
                .isInstanceOf(BusinessException.class);
        verify(users, never()).save(any());
    }

    @Test
    void resetPassword_jetonDejaUtilise_estRejete() {
        PasswordResetToken used = PasswordResetToken.builder().userId(4L)
                .expiresAt(Instant.now().plus(Duration.ofMinutes(10)))
                .usedAt(Instant.now()).build();
        when(tokens.findByTokenHash(anyString())).thenReturn(Optional.of(used));

        assertThatThrownBy(() -> service.resetPassword("raw", "NouveauMotDePasse1"))
                .isInstanceOf(BusinessException.class);
        verify(users, never()).save(any());
    }

    @Test
    void resetPassword_jetonInconnu_estRejete() {
        when(tokens.findByTokenHash(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.resetPassword("raw", "NouveauMotDePasse1"))
                .isInstanceOf(BusinessException.class);
    }
}
