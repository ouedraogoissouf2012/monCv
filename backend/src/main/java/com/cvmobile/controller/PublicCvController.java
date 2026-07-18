package com.cvmobile.controller;

import com.cvmobile.dto.PublicCvResponse;
import com.cvmobile.exception.PublicDocumentUnavailableException;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.security.PublicDocumentGuard;
import com.cvmobile.service.DocxGenerationService;
import com.cvmobile.service.PdfGenerationService;
import com.cvmobile.service.cv.PublicCvAccessService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;

@RestController
@RequestMapping("/api/cvs/public")
@RequiredArgsConstructor
@Tag(name = "CV public", description = "Consultation securisee des CV partages")
public class PublicCvController {
    private static final MediaType DOCX_MEDIA_TYPE = MediaType.parseMediaType(
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document");

    private final PublicCvAccessService publicCvAccessService;
    private final PdfGenerationService pdfGenerationService;
    private final DocxGenerationService docxGenerationService;
    private final PublicDocumentGuard documentGuard;
    private final BusinessMetrics businessMetrics;

    @GetMapping(value = "/{token}", produces = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Consulter un CV public")
    public ResponseEntity<PublicCvResponse> getPublicCv(
            @PathVariable String token,
            HttpServletRequest request) {
        return ResponseEntity.ok(publicCvAccessService.getPortfolio(
                token, request.getRemoteAddr()));
    }

    @GetMapping("/{token}/pdf")
    @Operation(summary = "Telecharger un CV public en PDF")
    public ResponseEntity<byte[]> downloadPdf(@PathVariable String token) {
        PublicCvAccessService.PdfSource source = publicCvAccessService.getPdfSource(token);
        byte[] document = documentGuard.generate(() -> businessMetrics.recordPdfGeneration(
                "PUBLIC_MODERNE",
                () -> pdfGenerationService.generateCvPdf(source.cv(), PdfTemplate.MODERNE)));
        publicCvAccessService.trackDownload(source.cvId());
        return attachment(document, MediaType.APPLICATION_PDF, "moncv.pdf");
    }

    @GetMapping("/{token}/docx")
    @Operation(summary = "Telecharger un CV public en DOCX")
    public ResponseEntity<byte[]> downloadDocx(@PathVariable String token) {
        PublicCvAccessService.DocxSource source = publicCvAccessService.getDocxSource(token);
        byte[] document = documentGuard.generate(() -> generateDocx(source));
        publicCvAccessService.trackDownload(source.cvId());
        return attachment(document, DOCX_MEDIA_TYPE, "moncv.docx");
    }

    @GetMapping("/{token}/photo")
    @Operation(summary = "Afficher la photo d'un CV public")
    public ResponseEntity<Resource> getPhoto(@PathVariable String token) {
        var photo = publicCvAccessService.getPhoto(token);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(photo.contentType()))
                .contentLength(photo.contentLength())
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline")
                .body(photo.resource());
    }

    @PostMapping(value = "/{token}/share", consumes = MediaType.APPLICATION_JSON_VALUE)
    @Operation(summary = "Comptabiliser une intention de partage public")
    public ResponseEntity<Void> trackShare(@PathVariable String token) {
        publicCvAccessService.trackShare(token);
        return ResponseEntity.noContent().build();
    }

    private byte[] generateDocx(PublicCvAccessService.DocxSource source) {
        try {
            return docxGenerationService.generate(source.cv());
        } catch (IOException exception) {
            throw new PublicDocumentUnavailableException(
                    "Generation DOCX temporairement indisponible");
        }
    }

    private ResponseEntity<byte[]> attachment(
            byte[] body, MediaType contentType, String filename) {
        return ResponseEntity.ok()
                .contentType(contentType)
                .contentLength(body.length)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + filename + "\"")
                .body(body);
    }
}
