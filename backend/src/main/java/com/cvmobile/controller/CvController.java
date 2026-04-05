package com.cvmobile.controller;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.CvService;
import com.cvmobile.service.DocxGenerationService;
import com.cvmobile.service.PdfGenerationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cvs")
@RequiredArgsConstructor
@Tag(name = "CV", description = "Gestion des CV")
@SecurityRequirement(name = "bearerAuth")
public class CvController {

    private final CvService cvService;
    private final PdfGenerationService pdfGenerationService;
    private final DocxGenerationService docxGenerationService;
    private final CvRepository cvRepository;

    @GetMapping
    @Operation(summary = "Obtenir tous les CV de l'utilisateur connecte")
    public ResponseEntity<List<CvResponse>> getAllCvs(@AuthenticationPrincipal User user) {
        List<CvResponse> cvs = cvService.getAllCvsByUserId(user.getId());
        return ResponseEntity.ok(cvs);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtenir un CV par son ID")
    public ResponseEntity<CvResponse> getCvById(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        CvResponse cv = cvService.getCvById(id, user.getId());
        return ResponseEntity.ok(cv);
    }

    @PostMapping
    @Operation(summary = "Creer un nouveau CV")
    public ResponseEntity<CvResponse> createCv(
            @Valid @RequestBody CvRequest request,
            @AuthenticationPrincipal User user) {
        CvResponse cv = cvService.createCv(request, user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(cv);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Mettre a jour un CV")
    public ResponseEntity<CvResponse> updateCv(
            @PathVariable Long id,
            @Valid @RequestBody CvRequest request,
            @AuthenticationPrincipal User user) {
        CvResponse cv = cvService.updateCv(id, request, user.getId());
        return ResponseEntity.ok(cv);
    }

    @GetMapping("/{id}/pdf")
    @Operation(summary = "Télécharger le CV en PDF (template: MODERNE, CLASSIQUE, MINIMALISTE)")
    public ResponseEntity<byte[]> downloadCvPdf(
            @PathVariable Long id,
            @RequestParam(defaultValue = "MODERNE") String template,
            @AuthenticationPrincipal User user) {
        CvResponse cv = cvService.getCvById(id, user.getId());
        PdfTemplate pdfTemplate;
        try {
            pdfTemplate = PdfTemplate.valueOf(template.toUpperCase());
        } catch (IllegalArgumentException e) {
            pdfTemplate = PdfTemplate.MODERNE;
        }
        byte[] pdf = pdfGenerationService.generateCvPdf(cv, pdfTemplate);

        String filename = "cv-" + id + "-" + pdfTemplate.name().toLowerCase() + ".pdf";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .body(pdf);
    }

    @GetMapping("/{id}/docx")
    @Operation(summary = "Telecharger le CV en DOCX (Word) — ATS-friendly")
    public ResponseEntity<byte[]> downloadCvDocx(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        // Charger l'entite complete (pas le DTO) pour la generation DOCX
        var cv = cvRepository.findByIdWithDetails(id)
                .orElseThrow(() -> new RuntimeException("CV non trouve"));
        if (!cv.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        try {
            byte[] docx = docxGenerationService.generate(cv);
            String filename = "cv-" + id + ".docx";
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(
                            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                    .body(docx);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/{id}/duplicate")
    @Operation(summary = "Dupliquer un CV")
    public ResponseEntity<CvResponse> duplicateCv(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        CvResponse cv = cvService.duplicateCv(id, user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(cv);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Supprimer un CV")
    public ResponseEntity<Void> deleteCv(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        cvService.deleteCv(id, user.getId());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/share")
    @Operation(summary = "Générer un lien de partage public pour un CV")
    public ResponseEntity<CvResponse> generateShareToken(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        CvResponse cv = cvService.generateShareToken(id, user.getId());
        return ResponseEntity.ok(cv);
    }

    @GetMapping("/public/{token}")
    @Operation(summary = "Accéder à un CV partagé publiquement")
    public ResponseEntity<CvResponse> getPublicCv(@PathVariable String token) {
        CvResponse cv = cvService.getCvByPublicToken(token);
        return ResponseEntity.ok(cv);
    }
}
