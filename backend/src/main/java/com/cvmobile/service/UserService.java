package com.cvmobile.service;

import com.cvmobile.model.User;
import com.cvmobile.repository.UserRepository;
import com.cvmobile.repository.UploadedPhotoRepository;
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;

import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService implements IUserService {

    private final UserRepository userRepository;
    private final UploadedPhotoRepository uploadedPhotoRepository;
    private final FileStorageService fileStorageService;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouve avec l'email: " + email));
    }

    public User findByEmail(String email) {
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new UsernameNotFoundException("Utilisateur non trouve avec l'email: " + email));
    }

    public Optional<User> findOptionalByEmail(String email) {
        return userRepository.findByEmailIgnoreCase(email);
    }

    public Optional<User> findByGoogleSubject(String googleSubject) {
        return userRepository.findByGoogleSubject(googleSubject);
    }

    public User findById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouve avec l'id: " + id));
    }

    public boolean existsByEmail(String email) {
        return userRepository.existsByEmailIgnoreCase(email);
    }

    public User save(User user) {
        return userRepository.save(user);
    }

    @Transactional
    public void deleteById(Long id) {
        List<String> filenames = uploadedPhotoRepository.findFilenamesByOwnerId(id);
        userRepository.deleteById(id);
        userRepository.flush();
        deleteFilesAfterCommit(filenames);
    }

    private void deleteFilesAfterCommit(List<String> filenames) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            deleteFiles(filenames);
            return;
        }
        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        deleteFiles(filenames);
                    }
                });
    }

    private void deleteFiles(List<String> filenames) {
        int failures = 0;
        for (String filename : filenames) {
            try {
                fileStorageService.deletePhoto(filename);
            } catch (RuntimeException exception) {
                failures++;
            }
        }
        if (failures > 0) {
            log.warn("Nettoyage incomplet des photos apres suppression de compte: failures={}",
                    failures);
        }
    }
}
