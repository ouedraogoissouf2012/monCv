package com.cvmobile.service;

import com.cvmobile.repository.UploadedPhotoRepository;
import com.cvmobile.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InOrder;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServicePhotoCleanupTest {
    @Mock UserRepository userRepository;
    @Mock UploadedPhotoRepository uploadedPhotoRepository;
    @Mock FileStorageService fileStorageService;

    @Test
    void deletesPhysicalPhotosOnlyAfterDatabaseDeletionIsFlushed() {
        when(uploadedPhotoRepository.findFilenamesByOwnerId(7L))
                .thenReturn(List.of("one.jpg", "two.png"));
        UserService service = new UserService(
                userRepository, uploadedPhotoRepository, fileStorageService);

        service.deleteById(7L);

        InOrder order = inOrder(userRepository, fileStorageService);
        order.verify(userRepository).deleteById(7L);
        order.verify(userRepository).flush();
        order.verify(fileStorageService).deletePhoto("one.jpg");
        order.verify(fileStorageService).deletePhoto("two.png");
    }

    @Test
    void defersPhysicalDeletionUntilTheTransactionCommits() {
        when(uploadedPhotoRepository.findFilenamesByOwnerId(7L))
                .thenReturn(List.of("one.jpg"));
        UserService service = new UserService(
                userRepository, uploadedPhotoRepository, fileStorageService);
        TransactionSynchronizationManager.initSynchronization();

        try {
            service.deleteById(7L);

            verifyNoInteractions(fileStorageService);
            var synchronizations = TransactionSynchronizationManager.getSynchronizations();
            assertThat(synchronizations).hasSize(1);

            synchronizations.getFirst().afterCommit();

            verify(fileStorageService).deletePhoto("one.jpg");
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }
}
