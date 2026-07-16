package com.cvmobile.service.file;

import com.cvmobile.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ImageFileValidatorTest {

    private final ImageFileValidator validator = new ImageFileValidator();

    @Test
    void acceptsMatchingPngSignature() {
        byte[] png = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        assertThatCode(() -> validator.validate(file("photo.png", "image/png", png)))
                .doesNotThrowAnyException();
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
    void rejectsOversizedImageBeforeReadingIt() {
        byte[] content = new byte[(int) ImageFileValidator.MAX_SIZE + 1];
        assertRejected(file("photo.jpg", "image/jpeg", content), "FILE_TOO_LARGE");
    }

    private MockMultipartFile file(String name, String mime, byte[] bytes) {
        return new MockMultipartFile("file", name, mime, bytes);
    }

    private void assertRejected(MockMultipartFile file, String code) {
        assertThatThrownBy(() -> validator.validate(file))
                .isInstanceOf(BusinessException.class)
                .extracting(error -> ((BusinessException) error).getCode())
                .isEqualTo(code);
    }
}
