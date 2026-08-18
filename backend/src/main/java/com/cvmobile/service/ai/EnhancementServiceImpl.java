package com.cvmobile.service.ai;

import com.cvmobile.config.AiEnhancementProperties;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.cv.CvOwnershipService;
import com.cvmobile.service.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Amelioration de CV par IA (issue #256) : LITE corrige l'orthographe et les
 * accents ; MEDIUM reformule ; MAX optimise le contenu pour les ATS.
 *
 * Orchestrateur : verifie la propriete du CV, appelle l'IA, puis delegue la
 * construction du prompt a {@link CvPromptBuilder} et l'analyse de la reponse a
 * {@link EnhanceResponseParser}.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EnhancementServiceImpl implements IEnhancementService {

    private final IAiClient aiClient;
    private final CvOwnershipService cvOwnershipService;
    private final NotificationService notificationService;
    private final AiEnhancementProperties enhancementProperties;
    private final CvPromptBuilder promptBuilder;
    private final EnhanceResponseParser responseParser;
    private final FactualFidelityGuard fidelityGuard;

    @Override
    public EnhanceCvResponse enhanceCv(Long cvId, Long userId, String level) {
        Cv cv = cvOwnershipService.requireOwnedCv(cvId, userId);
        // Les exceptions AiServiceException propagent sans masquer les erreurs config/quota/timeout.
        String prompt = promptBuilder.buildEnhancePrompt(cv, level);
        String rawContent = aiClient.complete(prompt, enhancementProperties.completionTokens());
        boolean fallback = aiClient.isFallbackResult();
        log.info("AI enhance response summary: {}", AiLogSanitizer.summarize(rawContent));
        EnhanceCvResponse response = responseParser.parse(rawContent, cv, level, fallback, false);
        notificationService.notifyAiTips(cv, response.getCorrectionCount());
        return response;
    }

    @Override
    public EnhanceCvResponse adaptCvToJob(Long cvId, Long userId, String jobDescription) {
        Cv cv = cvOwnershipService.requireOwnedCv(cvId, userId);
        String prompt = promptBuilder.buildAdaptPrompt(cv, jobDescription);
        String rawContent = aiClient.complete(prompt, enhancementProperties.completionTokens());
        boolean fallback = aiClient.isFallbackResult();
        log.info("AI adapt response summary: {}", AiLogSanitizer.summarize(rawContent));
        EnhanceCvResponse parsed = responseParser.parse(rawContent, cv, "MAX", fallback, true);
        return fidelityGuard.sanitize(cv, parsed);
    }
}
