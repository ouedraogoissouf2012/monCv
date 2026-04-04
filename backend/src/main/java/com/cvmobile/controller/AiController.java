package com.cvmobile.controller;

import com.cvmobile.dto.*;
import com.cvmobile.service.AiService;
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

    private final AiService aiService;

    @PostMapping("/suggest")
    @Operation(summary = "Générer des suggestions de bullet points pour une expérience")
    public ResponseEntity<SuggestResponse> suggest(@Valid @RequestBody SuggestRequest request) {
        SuggestResponse response = aiService.generateSuggestions(
                request.getPoste(),
                request.getEntreprise()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/enhance-cv")
    @Operation(summary = "Améliorer le CV avec l'IA (LITE / MEDIUM / MAX)")
    public ResponseEntity<EnhanceCvResponse> enhanceCv(@Valid @RequestBody EnhanceCvRequest request) {
        EnhanceCvResponse response = aiService.enhanceCv(request.getCvId(), request.getLevel());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/match-job")
    @Operation(summary = "Analyser la correspondance CV / offre d'emploi")
    public ResponseEntity<JobMatchResponse> matchJob(@Valid @RequestBody JobMatchRequest request) {
        JobMatchResponse response = aiService.matchJob(request.getCvId(), request.getJobDescription());
        return ResponseEntity.ok(response);
    }
}
