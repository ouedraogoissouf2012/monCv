package com.cvmobile.service;

import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.UploadedPhoto;
import com.cvmobile.model.User;
import com.cvmobile.repository.UploadedPhotoRepository;
import com.cvmobile.service.file.ImageFileValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class PhotoService {
    private final ImageFileValidator uploadValidator;
    private final FileStorageService fileStorageService;
    private final UploadedPhotoRepository uploadedPhotoRepository;

    @Transactional
    public String upload(MultipartFile file, User owner) {
        uploadValidator.validate(file);
        FileStorageService.StoredUpload stored = fileStorageService.storePhotoWithMetadata(file);
        try {
            uploadedPhotoRepository.saveAndFlush(new UploadedPhoto(stored.filename(), owner));
            return stored.url();
        } catch (RuntimeException exception) {
            deleteAfterFailure(stored.filename(), exception);
            throw exception;
        }
    }

    @Transactional(readOnly = true)
    public FileStorageService.StoredPhoto loadOwned(String filename, Long ownerId) {
        if (ownerId == null
                || !uploadedPhotoRepository.existsByFilenameAndOwnerId(filename, ownerId)) {
            throw notFound();
        }
        return fileStorageService.loadPhoto(filename).orElseThrow(this::notFound);
    }

    private void deleteAfterFailure(String filename, RuntimeException original) {
        try {
            fileStorageService.deletePhoto(filename);
        } catch (RuntimeException cleanupFailure) {
            original.addSuppressed(cleanupFailure);
        }
    }

    private ResourceNotFoundException notFound() {
        return new ResourceNotFoundException("Photo introuvable");
    }
}
