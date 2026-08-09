package com.cvmobile.service.auth;

import com.cvmobile.exception.BusinessException;
import com.cvmobile.model.PasswordResetToken;
import com.cvmobile.model.User;
import com.cvmobile.repository.PasswordResetTokenRepository;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.security.RateLimitResult;
import com.cvmobile.security.RateLimitService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
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
