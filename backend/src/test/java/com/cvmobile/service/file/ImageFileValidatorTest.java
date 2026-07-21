package com.cvmobile.service.file;

import com.cvmobile.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ImageFileValidatorTest {

    private final ImageFileValidator validator = new ImageFileValidator();

    @Test
    void acceptsMatchingPngSignature() {
        byte[] png = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        assertThatCode(() -> validator.validate(file("photo.png", "image/png", png)))
                .doesNotThrowAnyException();
    }

    @Test
    void acceptsMatchingJpegAndWebpSignatures() {
        byte[] jpeg = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
        byte[] webp = {0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50};

        assertThatCode(() -> validator.validate(file("photo.JPEG", "IMAGE/JPEG", jpeg)))
                .doesNotThrowAnyException();
        assertThatCode(() -> validator.validate(file("photo.webp", "image/webp", webp)))
                .doesNotThrowAnyException();
    }

    @Test
    void rejectsNullAndEmptyFiles() {
        assertRejected(null, "FILE_EMPTY");
        assertRejected(file("photo.png", "image/png", new byte[0]), "FILE_EMPTY");
    }

    @Test
    void rejectsScriptDisguisedAsImage() {
        assertRejected(file("photo.png", "image/png", "<script>alert(1)</script>".getBytes()),
                "INVALID_FILE_SIGNATURE");
    }

    @Test
    void rejectsMimeAndExtensionMismatch() {
        byte[] jpeg = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00};
        assertRejected(file("photo.png", "image/jpeg", jpeg), "INVALID_FILE_TYPE");
    }

    @Test
    void rejectsMissingFilenameOrMimeType() {
        byte[] png = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

        assertRejected(file(null, "image/png", png), "INVALID_FILE_TYPE");
        assertRejected(file("photo.png", null, png), "INVALID_FILE_TYPE");
        assertRejected(file("photo", "image/png", png), "INVALID_FILE_TYPE");
    }

    @Test
    void rejectsUnreadableContent() throws Exception {
        MultipartFile unreadable = mock(MultipartFile.class);
        when(unreadable.getSize()).thenReturn(12L);
        when(unreadable.getOriginalFilename()).thenReturn("photo.png");
        when(unreadable.getContentType()).thenReturn("image/png");
        when(unreadable.getInputStream()).thenThrow(new IOException("disk error"));

        assertRejected(unreadable, "INVALID_FILE_CONTENT");
    }

    @Test
    void rejectsOversizedImageBeforeReadingIt() {
        byte[] content = new byte[(int) ImageFileValidator.MAX_SIZE + 1];
        assertRejected(file("photo.jpg", "image/jpeg", content), "FILE_TOO_LARGE");
    }

    private MockMultipartFile file(String name, String mime, byte[] bytes) {
        return new MockMultipartFile("file", name, mime, bytes);
    }

    private void assertRejected(MultipartFile file, String code) {
        assertThatThrownBy(() -> validator.validate(file))
                .isInstanceOf(BusinessException.class)
                .extracting(error -> ((BusinessException) error).getCode())
                .isEqualTo(code);
    }
}
