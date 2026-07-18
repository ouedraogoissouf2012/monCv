package com.cvmobile.controller;

import com.cvmobile.dto.PublicCvResponse;
import com.cvmobile.exception.GlobalExceptionHandler;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.security.InvalidPublicShareTokenException;
import com.cvmobile.security.PublicCvSecurityHeadersFilter;
import com.cvmobile.security.PublicDocumentGuard;
import com.cvmobile.service.DocxGenerationService;
import com.cvmobile.service.PdfGenerationService;
import com.cvmobile.service.cv.PublicCvAccessService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import com.cvmobile.service.FileStorageService;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class PublicCvControllerWebTest {
    private static final String TOKEN = "A".repeat(43);

    @Mock PublicCvAccessService accessService;
    @Mock PdfGenerationService pdfGenerationService;
    @Mock DocxGenerationService docxGenerationService;
    @Mock PublicDocumentGuard documentGuard;
    @Mock BusinessMetrics businessMetrics;

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        PublicCvController controller = new PublicCvController(
                accessService, pdfGenerationService, docxGenerationService,
                documentGuard, businessMetrics);
        mvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .addFilters(new PublicCvSecurityHeadersFilter())
                .build();
    }

    @Test
    void returnsWhitelistOnlyWithNonCacheableSecurityHeaders() throws Exception {
        when(accessService.getPortfolio(TOKEN, "203.0.113.8")).thenReturn(response());

        mvc.perform(get("/api/cvs/public/{token}", TOKEN)
                        .with(request -> {
                            request.setRemoteAddr("203.0.113.8");
                            return request;
                        }))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(header().string("Cache-Control", "no-store, max-age=0"))
                .andExpect(header().string("Referrer-Policy", "no-referrer"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("X-Robots-Tag", "noindex, nofollow, noarchive"))
                .andExpect(jsonPath("$.titre").value("CV public"))
                .andExpect(jsonPath("$.id").doesNotExist())
                .andExpect(jsonPath("$.publicToken").doesNotExist())
                .andExpect(jsonPath("$.viewCount").doesNotExist())
                .andExpect(jsonPath("$.createdAt").doesNotExist());
    }

    @Test
    void requiresJsonForShareMutationAndAcceptsAnEmptyJsonObject() throws Exception {
        mvc.perform(post("/api/cvs/public/{token}/share", TOKEN)
                        .contentType(MediaType.TEXT_PLAIN).content("{}"))
                .andExpect(status().isUnsupportedMediaType());
        verifyNoInteractions(accessService);

        mvc.perform(post("/api/cvs/public/{token}/share", TOKEN)
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isNoContent());
        verify(accessService).trackShare(TOKEN);
    }

    @Test
    void malformedAndUnknownTokensUseTheSameGenericNotFoundContract() throws Exception {
        when(accessService.getPortfolio("invalid", "127.0.0.1"))
                .thenThrow(new InvalidPublicShareTokenException());

        mvc.perform(get("/api/cvs/public/invalid"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.details").doesNotExist());
    }

    @Test
    void streamsTokenScopedPhotosWithThePublicSecurityPolicy() throws Exception {
        byte[] png = {(byte) 0x89, 0x50, 0x4E, 0x47};
        when(accessService.getPhoto(TOKEN)).thenReturn(new FileStorageService.StoredPhoto(
                new ByteArrayResource(png), "image/png", png.length));

        mvc.perform(get("/api/cvs/public/{token}/photo", TOKEN))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_PNG))
                .andExpect(content().bytes(png))
                .andExpect(header().string("Cache-Control", "no-store, max-age=0"))
                .andExpect(header().string("Content-Disposition", "inline"));
    }

    private PublicCvResponse response() {
        return new PublicCvResponse(
                "CV public", null, List.of(), List.of(), List.of(), List.of(),
                List.of(), List.of(), new PublicCvResponse.Style("moderne", 1L, "Roboto"),
                false, false);
    }
}
