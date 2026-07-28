package com.cvmobile.controller;

import com.cvmobile.cv.adapter.in.web.CvResponseAssembler;
import com.cvmobile.cv.adapter.in.web.CvWebMapper;
import com.cvmobile.cv.application.usecase.CreateCvUseCase;
import com.cvmobile.cv.application.usecase.DeleteCvUseCase;
import com.cvmobile.cv.application.usecase.DuplicateCvUseCase;
import com.cvmobile.cv.application.usecase.GetCvUseCase;
import com.cvmobile.cv.application.usecase.UpdateCvUseCase;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.dto.CreateVariantRequest;
import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.model.User;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.service.DocxGenerationService;
import com.cvmobile.service.cv.CvOwnershipService;
import com.cvmobile.service.pdf.PdfGenerationService;
import com.cvmobile.service.import_.ICvImportService;
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
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/cvs")
@RequiredArgsConstructor
@Tag(name = "CV", description = "Gestion des CV")
@SecurityRequirement(name = "bearerAuth")
public class CvController {

    // CRUD : use cases du module CV migre (issue #255)
    private final GetCvUseCase getCvUseCase;
    private final CreateCvUseCase createCvUseCase;
    private final UpdateCvUseCase updateCvUseCase;
    private final DeleteCvUseCase deleteCvUseCase;
    private final DuplicateCvUseCase duplicateCvUseCase;
    private final CvWebMapper cvWebMapper;
    private final CvResponseAssembler cvResponseAssembler;

    // Partage public et variantes : encore portes par le service historique
    // (dependances non migrees) — cf. tranches 255-C+/255-E.
    private final com.cvmobile.service.cv.ICvService cvService;
    private final PdfGenerationService pdfGenerationService;
    private final DocxGenerationService docxGenerationService;
    private final CvOwnershipService cvOwnershipService;
    private final ICvImportService cvImportService;
    private final BusinessMetrics businessMetrics;

    @GetMapping
    @Operation(summary = "Obtenir tous les CV de l'utilisateur connecte")
    public ResponseEntity<List<CvResponse>> getAllCvs(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(cvResponseAssembler.assembleAll(user.getId()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtenir un CV par son ID")
    public ResponseEntity<CvResponse> getCvById(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        // Le use case tranche l'existence/appartenance (404 propre via
        // CvNotFoundException); l'assembleur ne fait que produire la reponse.
        getCvUseCase.get(id, user.getId());
        return ResponseEntity.ok(cvResponseAssembler.assemble(id, user.getId()));
    }

    @PostMapping
    @Operation(summary = "Creer un nouveau CV")
    public ResponseEntity<CvResponse> createCv(
            @Valid @RequestBody CvRequest request,
            @AuthenticationPrincipal User user) {
        Cv created = createCvUseCase.create(cvWebMapper.toDomain(request, user.getId()));
        CvResponse response = cvResponseAssembler.assemble(created.getId(), user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Mettre a jour un CV")
    public ResponseEntity<CvResponse> updateCv(
            @PathVariable Long id,
            @Valid @RequestBody CvRequest request,
            @AuthenticationPrincipal User user) {
        Cv changes = cvWebMapper.toDomain(request, user.getId());
        updateCvUseCase.update(id, user.getId(), changes);
        return ResponseEntity.ok(cvResponseAssembler.assemble(id, user.getId()));
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
        final PdfTemplate selectedTemplate = pdfTemplate;
        byte[] pdf = businessMetrics.recordPdfGeneration(
                selectedTemplate.name(),
                () -> pdfGenerationService.generateCvPdf(cv, selectedTemplate));

        String filename = "cv-" + id + "-" + selectedTemplate.name().toLowerCase() + ".pdf";
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
        var cv = cvOwnershipService.requireOwnedCv(id, user.getId());

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
        Cv copy = duplicateCvUseCase.duplicate(id, user.getId());
        CvResponse response = cvResponseAssembler.assemble(copy.getId(), user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Supprimer un CV")
    public ResponseEntity<Void> deleteCv(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        deleteCvUseCase.delete(id, user.getId());
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

    @PostMapping("/{id}/share/regenerate")
    @Operation(summary = "Regenerer le lien public d'un CV")
    public ResponseEntity<CvResponse> regenerateShareToken(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(cvService.regenerateShareToken(id, user.getId()));
    }

    @DeleteMapping("/{id}/share")
    @Operation(summary = "Desactiver le lien public d'un CV")
    public ResponseEntity<CvResponse> deactivateShare(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(cvService.deactivateShare(id, user.getId()));
    }

    @PutMapping("/{id}/share/settings")
    @Operation(summary = "Configurer les donnees et telechargements publics")
    public ResponseEntity<CvResponse> updateShareSettings(
            @PathVariable Long id,
            @RequestBody PublicShareSettingsRequest request,
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(
                cvService.updateShareSettings(id, request, user.getId()));
    }

    // ── Variantes ────────────────────────────────────────────────

    @PostMapping("/{id}/variant")
    @Operation(summary = "Creer une variante du CV adaptee a une offre d'emploi")
    public ResponseEntity<CvResponse> createVariant(
            @PathVariable Long id,
            @Valid @RequestBody CreateVariantRequest request,
            @AuthenticationPrincipal User user) {
        CvResponse variant = cvService.createVariant(
                id, request.getJobDescription(), request.getLabel(), user.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(variant);
    }

    @GetMapping("/{id}/variants")
    @Operation(summary = "Lister les variantes d'un CV")
    public ResponseEntity<List<CvResponse>> getVariants(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        List<CvResponse> variants = cvService.getVariantsByParentId(id, user.getId());
        return ResponseEntity.ok(variants);
    }

    // ── Import ──────────────────────────────────────────────────

    @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Importer un CV depuis un fichier PDF ou DOCX")
    public ResponseEntity<CvResponse> importCv(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal User user) {
        String format = detectImportFormat(file);
        try {
            CvRequest parsed = cvImportService.importCv(file);
            CvResponse created = cvService.createCv(parsed, user.getId());
            businessMetrics.recordImport(format, true);
            return ResponseEntity.status(HttpStatus.CREATED).body(created);
        } catch (RuntimeException ex) {
            businessMetrics.recordImport(format, false);
            throw ex;
        }
    }

    private String detectImportFormat(MultipartFile file) {
        String filename = file.getOriginalFilename();
        if (filename == null || !filename.contains(".")) {
            return "unknown";
        }
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }
}
