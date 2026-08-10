package com.cvmobile.controller;

import com.cvmobile.model.User;
import com.cvmobile.service.FileStorageService;
import com.cvmobile.service.PhotoService;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/// Tests unitaires du controleur d'upload (issue #258) : delegation au service
/// et, surtout, les en-tetes de securite du service de photos.
class UploadControllerTest {

    private final PhotoService photoService = mock(PhotoService.class);
    private final UploadController controller = new UploadController(photoService);

    @Test
    void uploadPhoto_delegueAuServiceEtRetourneLUrl() {
        MultipartFile file = mock(MultipartFile.class);
        User user = User.builder().id(1L).build();
        when(photoService.upload(file, user)).thenReturn("https://cdn.example/p.png");

        ResponseEntity<Map<String, String>> response =
                controller.uploadPhoto(file, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).containsEntry("url", "https://cdn.example/p.png");
    }

    @Test
    void servePhoto_sertLaRessourcePossedeeAvecLesEntetesDeSecurite() {
        User user = User.builder().id(7L).build();
        Resource resource = new ByteArrayResource("image-bytes".getBytes());
        when(photoService.loadOwned("photo.png", 7L)).thenReturn(
                new FileStorageService.StoredPhoto(resource, "image/png", 11L));

        ResponseEntity<Resource> response = controller.servePhoto("photo.png", user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(resource);

        HttpHeaders headers = response.getHeaders();
        // Photo privee : jamais mise en cache, jamais sniffee, variant sur l'auth.
        assertThat(headers.getCacheControl()).isEqualTo("private, no-store");
        assertThat(headers.getFirst("X-Content-Type-Options")).isEqualTo("nosniff");
        assertThat(headers.getFirst(HttpHeaders.CONTENT_DISPOSITION)).isEqualTo("inline");
        assertThat(headers.getVary()).contains(HttpHeaders.AUTHORIZATION);
        assertThat(headers.getContentType()).isEqualTo(MediaType.IMAGE_PNG);
        assertThat(headers.getContentLength()).isEqualTo(11L);
    }
}
