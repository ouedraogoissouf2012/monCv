package com.cvmobile.controller;

import com.cvmobile.dto.*;
import com.cvmobile.service.ai.AiStatusService;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.ai.IJobMatchService;
import com.cvmobile.service.ai.IResumeGeneratorService;
import com.cvmobile.service.ai.ISuggestionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
                request.getEntreprise()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/generate-resume")
    @Operation(summary = "Generer un resume professionnel avec l'IA")
    public ResponseEntity<java.util.Map<String, String>> generateResume(
            @RequestBody GenerateResumeRequest request) {
        var response = resumeGeneratorService.generateResume(
                request.getTitrePoste(),
                request.getCompetences(),
                request.getExperience()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/enhance-cv")
    @Operation(summary = "Améliorer le CV avec l'IA (LITE / MEDIUM / MAX)")
    public ResponseEntity<EnhanceCvResponse> enhanceCv(@Valid @RequestBody EnhanceCvRequest request) {
        EnhanceCvResponse response = enhancementService.enhanceCv(request.getCvId(), request.getLevel());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/match-job")
    @Operation(summary = "Analyser la correspondance CV / offre d'emploi")
    public ResponseEntity<JobMatchResponse> matchJob(@Valid @RequestBody JobMatchRequest request) {
        JobMatchResponse response = jobMatchService.matchJob(request.getCvId(), request.getJobDescription());
        return ResponseEntity.ok(response);
    }
}
