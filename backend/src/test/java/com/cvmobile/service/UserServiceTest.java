package com.cvmobile.service;

import com.cvmobile.model.User;
import com.cvmobile.repository.UploadedPhotoRepository;
import com.cvmobile.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Couvre les acces utilisateur simples et le chemin d'echec du nettoyage photo
 * (issue #258). Le flux transactionnel du nettoyage est teste separement dans
 * {@link UserServicePhotoCleanupTest}.
 */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock UserRepository userRepository;
    @Mock UploadedPhotoRepository uploadedPhotoRepository;
    @Mock FileStorageService fileStorageService;
    @InjectMocks UserService service;

    private User user() {
        return User.builder().id(1L).email("test@example.com").build();
    }

    @Test
    void loadUserByUsername_retourneLUtilisateur() {
        when(userRepository.findByEmailIgnoreCase("test@example.com"))
                .thenReturn(Optional.of(user()));

        UserDetails details = service.loadUserByUsername("test@example.com");

        assertThat(details.getUsername()).isEqualTo("test@example.com");
    }

    @Test
    void loadUserByUsername_leveQuandInconnu() {
        when(userRepository.findByEmailIgnoreCase("absent@example.com"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.loadUserByUsername("absent@example.com"))
                .isInstanceOf(UsernameNotFoundException.class);
    }

    @Test
    void findById_leveQuandInconnu() {
        when(userRepository.findById(9L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(9L))
                .isInstanceOf(RuntimeException.class);
    }

    @Test
    void lecturesSimples_deleguentAuRepository() {
        User u = user();
        when(userRepository.findByEmailIgnoreCase("test@example.com")).thenReturn(Optional.of(u));
        when(userRepository.findByGoogleSubject("sub")).thenReturn(Optional.of(u));
        when(userRepository.findById(1L)).thenReturn(Optional.of(u));
        when(userRepository.existsByEmailIgnoreCase("test@example.com")).thenReturn(true);
        when(userRepository.save(u)).thenReturn(u);

        assertThat(service.findByEmail("test@example.com")).isSameAs(u);
        assertThat(service.findOptionalByEmail("test@example.com")).contains(u);
        assertThat(service.findByGoogleSubject("sub")).contains(u);
        assertThat(service.findById(1L)).isSameAs(u);
        assertThat(service.existsByEmail("test@example.com")).isTrue();
        assertThat(service.save(u)).isSameAs(u);
    }

    @Test
    void deleteById_absorbeEtJournaliseUnNettoyagePhotoIncomplet() {
        when(uploadedPhotoRepository.findFilenamesByOwnerId(1L))
                .thenReturn(List.of("broken.jpg"));
        doThrow(new RuntimeException("disk error"))
                .when(fileStorageService).deletePhoto("broken.jpg");

        // Ne doit jamais propager : l'echec de nettoyage est absorbe (et compte).
        service.deleteById(1L);

        verify(userRepository).deleteById(1L);
        verify(fileStorageService).deletePhoto("broken.jpg");
    }
}
