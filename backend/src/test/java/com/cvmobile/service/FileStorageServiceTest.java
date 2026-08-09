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

    @Test
    void resoutLesTypesMimePngEtWebp() {
        FileStorageService service = new FileStorageService(directory.toString());
        String png = filenameOf(service.storePhoto(
                new MockMultipartFile("file", "a.png", "image/png", new byte[]{1})));
        String webp = filenameOf(service.storePhoto(
                new MockMultipartFile("file", "b.webp", "image/webp", new byte[]{2})));

        assertThat(service.loadPhoto(png).orElseThrow().contentType())
                .isEqualTo("image/png");
        assertThat(service.loadPhoto(webp).orElseThrow().contentType())
                .isEqualTo("image/webp");
    }

    @Test
    void loadPhotoVidePourUnNomOpaqueValideMaisSansFichier() {
        FileStorageService service = new FileStorageService(directory.toString());

        // Nom au format opaque attendu, mais aucun fichier correspondant sur
        // disque : la garde isRegularFile renvoie Optional.empty().
        assertThat(service.loadPhoto("0123abcd-0123-0123-0123-0123456789ab.png"))
                .isEmpty();
    }

    @Test
    void deletePhotoIgnoreUnNomInvalideSansLever() {
        FileStorageService service = new FileStorageService(directory.toString());

        // Ne doit ni lever ni sortir du repertoire d'upload.
        service.deletePhoto("../../secret.jpg");
        service.deletePhoto(null);
    }

    @Test
    void nettoieLeFichierPartielEtLeveSiLaCopieEchoue() {
        FileStorageService service = new FileStorageService(directory.toString());
        // Extension valide, mais le flux echoue a la lecture -> la copie leve une
        // IOException : le service supprime le fichier partiel puis re-signale.
        var failing = new MockMultipartFile("file", "x.png", "image/png", new byte[]{1}) {
            @Override
            public java.io.InputStream getInputStream() throws java.io.IOException {
                throw new java.io.IOException("flux indisponible");
            }
        };

        assertThatThrownBy(() -> service.storePhoto(failing))
                .isInstanceOf(FileStorageException.class)
                .hasMessageContaining("sauvegarde");
    }

    private static String filenameOf(String url) {
        return url.substring(url.lastIndexOf('/') + 1);
    }
}
