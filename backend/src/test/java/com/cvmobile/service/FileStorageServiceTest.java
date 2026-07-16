package com.cvmobile.service;

import com.cvmobile.exception.FileStorageException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FileStorageServiceTest {
    @TempDir Path directory;

    @Test
    void storesAndLoadsOnlyOpaqueImageFilenames() {
        FileStorageService service = new FileStorageService(directory.toString());
        var file = new MockMultipartFile(
                "file", "portrait.JPG", "image/jpeg",
                new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF});

        String url = service.storePhoto(file);
        String filename = url.substring(url.lastIndexOf('/') + 1);

        assertThat(filename).matches("[0-9a-f-]{36}\\.jpg");
        assertThat(service.loadPhoto(filename).orElseThrow().contentType())
                .isEqualTo("image/jpeg");
        assertThat(service.loadPhoto("../../secret.jpg")).isEmpty();

        service.deletePhoto(filename);
        assertThat(service.loadPhoto(filename)).isEmpty();
    }

    @Test
    void storageLayerAlsoRejectsUnexpectedExtensions() {
        FileStorageService service = new FileStorageService(directory.toString());
        var file = new MockMultipartFile("file", "payload.svg", "image/svg+xml", "x".getBytes());

        assertThatThrownBy(() -> service.storePhoto(file))
                .isInstanceOf(FileStorageException.class)
                .hasMessageContaining("Extension");
    }
}
