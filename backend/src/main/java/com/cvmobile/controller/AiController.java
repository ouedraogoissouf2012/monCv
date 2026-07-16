package com.cvmobile.controller;

import com.cvmobile.dto.*;
import com.cvmobile.model.User;
import com.cvmobile.service.ai.AiStatusService;
import com.cvmobile.service.ai.IApplicationMessageService;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.ai.IJobMatchService;
import com.cvmobile.service.ai.IResumeGeneratorService;
import com.cvmobile.service.ai.ISuggestionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Tag(name = "AI", description = "Suggestions intelligentes pour le CV")
@SecurityRequirement(name = "bearerAuth")
public class AiController {

    private final ISuggestionService suggestionService;
    private final IResumeGeneratorService resumeGeneratorService;
    private final IEnhancementService enhancementService;
    private final IJobMatchService jobMatchService;
    private final IApplicationMessageService applicationMessageService;
    private final AiStatusService aiStatusService;

    @GetMapping("/status")
    @Operation(summary = "Etat du sous-systeme IA (providers disponibles, circuit breaker, etc.)")
    public ResponseEntity<AiStatusResponse> status() {
        return ResponseEntity.ok(aiStatusService.currentStatus());
    }

    @PostMapping("/suggest")
    @Operation(summary = "Générer des suggestions de bullet points pour une expérience")
    public ResponseEntity<SuggestResponse> suggest(@Valid @RequestBody SuggestRequest request) {
        SuggestResponse response = suggestionService.generateSuggestions(
                request.getPoste(),
                request.getEntreprise(),
                request.getDescription()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/generate-resume")
    @Operation(summary = "Generer un resume professionnel avec l'IA")
    public ResponseEntity<java.util.Map<String, Object>> generateResume(
            @Valid @RequestBody GenerateResumeRequest request) {
        var response = resumeGeneratorService.generateResume(
                request.getTitrePoste(),
                request.getCompetences(),
                request.getExperience()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/enhance-cv")
    @Operation(summary = "Améliorer le CV avec l'IA (LITE / MEDIUM / MAX)",
            description = "Le CV doit appartenir à l'utilisateur authentifié.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "CV amélioré"),
            @ApiResponse(responseCode = "401", description = "Authentification requise"),
            @ApiResponse(responseCode = "404", description = "CV absent ou non détenu par l'utilisateur")
    })
    public ResponseEntity<EnhanceCvResponse> enhanceCv(
            @Valid @RequestBody EnhanceCvRequest request,
            @AuthenticationPrincipal User user) {
        EnhanceCvResponse response = enhancementService.enhanceCv(
                request.getCvId(), user.getId(), request.getLevel());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/match-job")
    @Operation(summary = "Analyser la correspondance CV / offre d'emploi",
            description = "Le CV doit appartenir à l'utilisateur authentifié.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Correspondance analysée"),
            @ApiResponse(responseCode = "401", description = "Authentification requise"),
            @ApiResponse(responseCode = "404", description = "CV absent ou non détenu par l'utilisateur")
    })
    public ResponseEntity<JobMatchResponse> matchJob(
            @Valid @RequestBody JobMatchRequest request,
            @AuthenticationPrincipal User user) {
        JobMatchResponse response = jobMatchService.matchJob(
                request.getCvId(), user.getId(), request.getJobDescription());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/application-messages")
    @Operation(summary = "Generer les textes de candidature adaptes au CV et a l'offre",
            description = "Le CV doit appartenir à l'utilisateur authentifié.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Textes générés"),
            @ApiResponse(responseCode = "401", description = "Authentification requise"),
            @ApiResponse(responseCode = "404", description = "CV absent ou non détenu par l'utilisateur")
    })
    public ResponseEntity<ApplicationMessagesResponse> generateApplicationMessages(
            @Valid @RequestBody ApplicationMessagesRequest request,
            @AuthenticationPrincipal User user) {
        return ResponseEntity.ok(applicationMessageService.generate(
                request.getCvId(), user.getId(), request.getJobDescription(), request.getTone()));
    }
}
