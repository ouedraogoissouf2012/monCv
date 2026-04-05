package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service d'import de CV depuis un fichier PDF ou DOCX.
 * Extrait le texte puis utilise DeepSeek pour parser en JSON structure.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CvImportService {

    @Value("${ai.deepseek.api-key:}")
    private String apiKey;

    @Value("${ai.deepseek.model:deepseek-chat}")
    private String model;

    @Value("${ai.deepseek.base-url:https://api.deepseek.com/v1}")
    private String baseUrl;

    private final RestTemplateBuilder restTemplateBuilder;

    /**
     * Importe un CV depuis un fichier PDF ou DOCX.
     * Retourne un CvRequest pre-rempli.
     */
    public CvRequest importCv(MultipartFile file) {
        String text = extractText(file);
        if (text.isBlank()) {
            throw new BusinessException("EMPTY_FILE", "Le fichier ne contient pas de texte exploitable");
        }
        log.info("Texte extrait du CV ({} caracteres)", text.length());
        return parseWithAi(text);
    }

    // ── Extraction texte ─────────────────────────────────────────

    private String extractText(MultipartFile file) {
        String filename = file.getOriginalFilename();
        if (filename == null) throw new BusinessException("NO_FILENAME", "Nom de fichier manquant");

        String lower = filename.toLowerCase();
        try {
            if (lower.endsWith(".pdf")) {
                return extractPdfText(file);
            } else if (lower.endsWith(".docx")) {
                return extractDocxText(file);
            } else {
                throw new BusinessException("UNSUPPORTED_FORMAT",
                        "Format non supporte. Utilisez PDF ou DOCX.");
            }
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Erreur extraction texte: {}", e.getMessage());
            throw new BusinessException("EXTRACTION_ERROR",
                    "Impossible de lire le fichier: " + e.getMessage());
        }
    }

    private String extractPdfText(MultipartFile file) throws IOException {
        try (PDDocument doc = Loader.loadPDF(file.getBytes())) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(doc).trim();
        }
    }

    private String extractDocxText(MultipartFile file) throws IOException {
        try (XWPFDocument doc = new XWPFDocument(file.getInputStream())) {
            return doc.getParagraphs().stream()
                    .map(XWPFParagraph::getText)
                    .filter(t -> t != null && !t.isBlank())
                    .collect(Collectors.joining("\n"));
        }
    }

    // ── Parsing IA ───────────────────────────────────────────────

    private CvRequest parseWithAi(String text) {
        if (apiKey == null || apiKey.isBlank()) {
            return buildFallbackParse(text);
        }

        try {
            String prompt = buildParsePrompt(text);
            String json = callDeepSeek(prompt);
            log.info("DeepSeek parse response: {}", json.substring(0, Math.min(200, json.length())));
            return parseJsonResponse(json);
        } catch (Exception e) {
            log.warn("IA parsing failed, using fallback: {}", e.getMessage());
            return buildFallbackParse(text);
        }
    }

    private String buildParsePrompt(String cvText) {
        return "Tu es un expert en parsing de CV. Analyse ce texte de CV et extrais les informations.\n\n"
                + "Reponds UNIQUEMENT avec un JSON valide (pas de texte avant ou apres) dans ce format:\n"
                + "{\n"
                + "  \"titre\": \"titre du poste\",\n"
                + "  \"personalInfo\": {\n"
                + "    \"prenom\": \"\", \"nom\": \"\", \"email\": \"\", \"telephone\": \"\",\n"
                + "    \"ville\": \"\", \"pays\": \"\", \"titrePoste\": \"\", \"resumeProfessionnel\": \"\"\n"
                + "  },\n"
                + "  \"experiences\": [{\"poste\": \"\", \"entreprise\": \"\", \"lieu\": \"\", \"dateDebut\": \"YYYY-MM-DD\", \"dateFin\": \"YYYY-MM-DD\", \"description\": \"\"}],\n"
                + "  \"educations\": [{\"diplome\": \"\", \"etablissement\": \"\", \"dateDebut\": \"YYYY-MM-DD\", \"dateFin\": \"YYYY-MM-DD\", \"description\": \"\"}],\n"
                + "  \"skills\": [{\"nom\": \"\", \"niveau\": 3}],\n"
                + "  \"languages\": [{\"langue\": \"\", \"niveau\": \"B1\"}]\n"
                + "}\n\n"
                + "REGLES:\n"
                + "- Separe les competences individuellement (pas en bloc)\n"
                + "- Niveau competence: 1-5 (1=debutant, 5=expert)\n"
                + "- Dates au format YYYY-MM-DD, utilise le 01 si jour inconnu\n"
                + "- Si une info manque, mets une chaine vide\n"
                + "- Le resume professionnel doit etre le paragraphe d'introduction du CV\n\n"
                + "TEXTE DU CV:\n" + cvText;
    }

    private String callDeepSeek(String prompt) {
        RestTemplate rest = restTemplateBuilder.build();

        Map<String, Object> body = Map.of(
                "model", model,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "max_tokens", 2000,
                "temperature", 0.1
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(apiKey);

        ResponseEntity<Map<String, Object>> response = rest.exchange(
                baseUrl + "/chat/completions",
                HttpMethod.POST,
                new HttpEntity<>(body, headers),
                new org.springframework.core.ParameterizedTypeReference<>() {});

        Map<String, Object> respBody = response.getBody();
        if (respBody == null) throw new RuntimeException("Empty response");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> choices = (List<Map<String, Object>>) respBody.get("choices");
        @SuppressWarnings("unchecked")
        Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
        String content = (String) message.get("content");

        // Nettoyer: retirer les ```json ``` si present
        content = content.replaceAll("^```json\\s*", "").replaceAll("```\\s*$", "").trim();
        return content;
    }

    @SuppressWarnings("unchecked")
    private CvRequest parseJsonResponse(String json) {
        try {
            var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            mapper.configure(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
            return mapper.readValue(json, CvRequest.class);
        } catch (Exception e) {
            log.warn("JSON parsing failed: {}", e.getMessage());
            throw new RuntimeException("Impossible de parser la reponse IA");
        }
    }

    // ── Fallback sans IA ─────────────────────────────────────────

    private CvRequest buildFallbackParse(String text) {
        // Extraction basique sans IA
        CvRequest req = new CvRequest();
        req.setTitre("CV importe");

        CvRequest.PersonalInfoDto info = new CvRequest.PersonalInfoDto();

        // Chercher email
        var emailMatcher = java.util.regex.Pattern.compile("[\\w.+-]+@[\\w-]+\\.[a-zA-Z]{2,}")
                .matcher(text);
        if (emailMatcher.find()) info.setEmail(emailMatcher.group());

        // Chercher telephone
        var phoneMatcher = java.util.regex.Pattern.compile("(?:\\+\\d{1,3}[\\s-]?)?(?:\\d[\\s.-]?){8,12}")
                .matcher(text);
        if (phoneMatcher.find()) info.setTelephone(phoneMatcher.group().trim());

        // Premiere ligne = probablement le nom
        String[] lines = text.split("\n");
        if (lines.length > 0) {
            String firstLine = lines[0].trim();
            if (firstLine.length() < 50) {
                String[] parts = firstLine.split("\\s+", 2);
                if (parts.length >= 2) {
                    info.setPrenom(parts[0]);
                    info.setNom(parts[1]);
                }
            }
        }

        info.setResumeProfessionnel(text.length() > 500 ? text.substring(0, 500) : text);
        req.setPersonalInfo(info);

        return req;
    }
}
