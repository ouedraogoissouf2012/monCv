package com.cvmobile.service;

import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.UploadedPhoto;
import com.cvmobile.model.User;
import com.cvmobile.repository.UploadedPhotoRepository;
import com.cvmobile.service.file.ImageFileValidator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PhotoServiceTest {
    private static final String FILENAME = "123e4567-e89b-12d3-a456-426614174000.jpg";

    @Mock ImageFileValidator validator;
    @Mock FileStorageService storage;
    @Mock UploadedPhotoRepository repository;

    @Test
    void recordsOwnershipBeforeReturningUploadedUrl() {
        var file = new MockMultipartFile("file", "portrait.jpg", "image/jpeg", new byte[]{1});
        User owner = User.builder().id(7L).build();
        when(storage.storePhotoWithMetadata(file)).thenReturn(
                new FileStorageService.StoredUpload(FILENAME, "/api/uploads/photos/" + FILENAME));
        when(repository.saveAndFlush(any(UploadedPhoto.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        String result = service().upload(file, owner);

        assertThat(result).isEqualTo("/api/uploads/photos/" + FILENAME);
        verify(validator).validate(file);
        verify(repository).saveAndFlush(any(UploadedPhoto.class));
    }

    @Test
    void removesStoredFileWhenOwnershipPersistenceFails() {
        var file = new MockMultipartFile("file", "portrait.jpg", "image/jpeg", new byte[]{1});
        when(storage.storePhotoWithMetadata(file)).thenReturn(
                new FileStorageService.StoredUpload(FILENAME, "/api/uploads/photos/" + FILENAME));
        doThrow(new IllegalStateException("database unavailable"))
                .when(repository).saveAndFlush(any(UploadedPhoto.class));

        assertThatThrownBy(() -> service().upload(file, User.builder().id(7L).build()))
                .isInstanceOf(IllegalStateException.class);
        verify(storage).deletePhoto(FILENAME);
    }

    @Test
    void hidesWhetherAFileExistsWhenCallerIsNotTheOwner() {
        assertThatThrownBy(() -> service().loadOwned(FILENAME, 99L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Photo introuvable");
        verify(repository).existsByFilenameAndOwnerId(FILENAME, 99L);
    }

    @Test
    void loadsOnlyAnOwnedRegularPhoto() {
        var expected = new FileStorageService.StoredPhoto(
                new ByteArrayResource(new byte[]{1, 2, 3}), "image/jpeg", 3);
        when(repository.existsByFilenameAndOwnerId(FILENAME, 7L)).thenReturn(true);
        when(storage.loadPhoto(FILENAME)).thenReturn(java.util.Optional.of(expected));

        assertThat(service().loadOwned(FILENAME, 7L)).isSameAs(expected);
    }

    private PhotoService service() {
        return new PhotoService(validator, storage, repository);
    }
}
