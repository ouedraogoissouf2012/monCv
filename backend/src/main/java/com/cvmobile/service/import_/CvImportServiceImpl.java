package com.cvmobile.service.import_;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.exception.BusinessException;
import com.cvmobile.service.ai.client.IAiClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Import de CV depuis un fichier PDF ou DOCX.
 * 1. Extrait le texte brut du fichier
 * 2. Envoie le texte a l'IA pour structuration en sections CV
 * 3. Parse la reponse IA en CvRequest
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CvImportServiceImpl implements ICvImportService {

    private final IAiClient aiClient;

    @Override
    public CvRequest importCv(MultipartFile file) {
        String filename = file.getOriginalFilename();
        if (filename == null) throw new BusinessException("IMPORT_ERROR", "Nom de fichier manquant");

        String text;
        String ext = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();

        try {
            text = switch (ext) {
                case "pdf" -> extractTextFromPdf(file);
                case "docx" -> extractTextFromDocx(file);
                default -> throw new BusinessException("IMPORT_ERROR",
                        "Format non supporte. Utilisez PDF ou DOCX.");
            };
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Erreur extraction texte du fichier {}", filename, e);
            throw new BusinessException("IMPORT_ERROR", "Impossible de lire le fichier");
        }

        if (text.isBlank()) {
            throw new BusinessException("IMPORT_ERROR",
                    "Le fichier ne contient pas de texte exploitable (PDF scanne ?)");
        }

        log.info("Texte extrait du CV ({} caracteres)", text.length());

        if (!aiClient.isAvailable()) {
            return buildFallbackImport(text, filename);
        }

        try {
            return parseWithAi(text, filename);
        } catch (Exception e) {
            log.warn("IA import failed, using fallback: {}", e.getMessage());
            return buildFallbackImport(text, filename);
        }
    }

    // ── Extraction texte ────────────────────────────────────────────

    private String extractTextFromPdf(MultipartFile file) throws IOException {
        try (PDDocument doc = Loader.loadPDF(file.getBytes())) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(doc).strip();
        }
    }

    private String extractTextFromDocx(MultipartFile file) throws IOException {
        try (XWPFDocument doc = new XWPFDocument(file.getInputStream())) {
            return doc.getParagraphs().stream()
                    .map(XWPFParagraph::getText)
                    .filter(t -> t != null && !t.isBlank())
                    .collect(Collectors.joining("\n"));
        }
    }

    // ── Parsing IA ──────────────────────────────────────────────────

    private CvRequest parseWithAi(String text, String filename) {
        String prompt = buildParsePrompt(text);
        String response = aiClient.complete(prompt, 3000);
        log.info("IA import response:\n{}", response);
        return parseAiResponse(response, filename);
    }

    private String buildParsePrompt(String text) {
        return """
                Tu es un expert en analyse de CV. Extrais les informations structurees de ce CV.

                Reponds EXACTEMENT dans ce format (laisse vide si non trouve) :

                NOM: (nom de famille)
                PRENOM: (prenom)
                EMAIL: (email)
                TELEPHONE: (telephone)
                VILLE: (ville)
                PAYS: (pays)
                TITRE_POSTE: (titre du poste actuel ou recherche)
                RESUME: (resume professionnel, 2-3 phrases)

                EXPERIENCES:
                - POSTE: ... | ENTREPRISE: ... | LIEU: ... | DESCRIPTION: ...
                - POSTE: ... | ENTREPRISE: ... | LIEU: ... | DESCRIPTION: ...

                FORMATIONS:
                - DIPLOME: ... | ETABLISSEMENT: ... | DOMAINE: ...
                - DIPLOME: ... | ETABLISSEMENT: ... | DOMAINE: ...

                COMPETENCES:
                - competence1
                - competence2

                LANGUES:
                - langue1: niveau
                - langue2: niveau

                ---
                CONTENU DU CV :
                """ + text;
    }

    private CvRequest parseAiResponse(String response, String filename) {
        String titre = extractValue(response, "TITRE_POSTE:");
        if (titre.isBlank()) titre = filename.replaceAll("\\.(pdf|docx)$", "");

        var personalInfo = CvRequest.PersonalInfoDto.builder()
                .nom(extractValue(response, "NOM:"))
                .prenom(extractValue(response, "PRENOM:"))
                .email(extractValue(response, "EMAIL:"))
                .telephone(extractValue(response, "TELEPHONE:"))
                .ville(extractValue(response, "VILLE:"))
                .pays(extractValue(response, "PAYS:"))
                .titrePoste(titre)
                .resumeProfessionnel(extractValue(response, "RESUME:"))
                .build();

        List<CvRequest.ExperienceDto> experiences = parseExperiences(response);
        List<CvRequest.EducationDto> educations = parseEducations(response);
        List<CvRequest.SkillDto> skills = parseSkills(response);
        List<CvRequest.LanguageDto> languages = parseLanguages(response);

        return CvRequest.builder()
                .titre(titre.isBlank() ? "CV importe" : titre)
                .personalInfo(personalInfo)
                .experiences(experiences)
                .educations(educations)
                .skills(skills)
                .languages(languages)
                .build();
    }

    // ── Parsers de sections ─────────────────────────────────────────

    private String extractValue(String content, String marker) {
        int start = content.indexOf(marker);
        if (start == -1) return "";
        int lineEnd = content.indexOf('\n', start);
        if (lineEnd == -1) lineEnd = content.length();
        return content.substring(start + marker.length(), lineEnd).strip();
    }

    private List<CvRequest.ExperienceDto> parseExperiences(String response) {
        List<String> lines = extractSection(response, "EXPERIENCES:", "FORMATIONS:");
        List<CvRequest.ExperienceDto> result = new ArrayList<>();
        for (String line : lines) {
            Map<String, String> fields = parseFieldLine(line);
            if (fields.containsKey("POSTE")) {
                result.add(CvRequest.ExperienceDto.builder()
                        .poste(fields.getOrDefault("POSTE", ""))
                        .entreprise(fields.getOrDefault("ENTREPRISE", ""))
                        .lieu(fields.getOrDefault("LIEU", ""))
                        .description(fields.getOrDefault("DESCRIPTION", ""))
                        .build());
            }
        }
        return result;
    }

    private List<CvRequest.EducationDto> parseEducations(String response) {
        List<String> lines = extractSection(response, "FORMATIONS:", "COMPETENCES:");
        List<CvRequest.EducationDto> result = new ArrayList<>();
        for (String line : lines) {
            Map<String, String> fields = parseFieldLine(line);
            if (fields.containsKey("DIPLOME")) {
                result.add(CvRequest.EducationDto.builder()
                        .diplome(fields.getOrDefault("DIPLOME", ""))
                        .etablissement(fields.getOrDefault("ETABLISSEMENT", ""))
                        .domaine(fields.getOrDefault("DOMAINE", ""))
                        .build());
            }
        }
        return result;
    }

    private List<CvRequest.SkillDto> parseSkills(String response) {
        List<String> lines = extractSection(response, "COMPETENCES:", "LANGUES:");
        return lines.stream()
                .map(l -> l.replaceAll("^[\\-\\*•]+\\s*", "").strip())
                .filter(l -> !l.isBlank())
                .limit(10)
                .map(nom -> CvRequest.SkillDto.builder().nom(nom).niveau(3).build())
                .collect(Collectors.toList());
    }

    private List<CvRequest.LanguageDto> parseLanguages(String response) {
        List<String> lines = extractSection(response, "LANGUES:", "---");
        List<CvRequest.LanguageDto> result = new ArrayList<>();
        for (String line : lines) {
            String cleaned = line.replaceAll("^[\\-\\*•]+\\s*", "").strip();
            if (cleaned.isBlank()) continue;
            String[] parts = cleaned.split(":\\s*", 2);
            String langue = parts[0].strip();
            String niveau = parts.length > 1 ? mapLanguageLevel(parts[1].strip()) : "INTERMEDIAIRE";
            result.add(CvRequest.LanguageDto.builder()
                    .langue(langue)
                    .niveau(com.cvmobile.model.Language.NiveauLangue.valueOf(niveau))
                    .build());
        }
        return result;
    }

    private String mapLanguageLevel(String level) {
        String lc = level.toLowerCase();
        if (lc.contains("natif") || lc.contains("maternel")) return "NATIF";
        if (lc.contains("c2") || lc.contains("bilingue")) return "C2";
        if (lc.contains("c1") || lc.contains("courant") || lc.contains("avance")) return "C1";
        if (lc.contains("b2")) return "B2";
        if (lc.contains("b1") || lc.contains("intermediaire")) return "B1";
        if (lc.contains("a2") || lc.contains("elementaire")) return "A2";
        if (lc.contains("a1") || lc.contains("debutant")) return "A1";
        return "INTERMEDIAIRE";
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private List<String> extractSection(String content, String startMarker, String endMarker) {
        int start = content.indexOf(startMarker);
        if (start == -1) return List.of();
        start += startMarker.length();

        int end = content.indexOf(endMarker, start);
        if (end == -1) end = content.length();

        String section = content.substring(start, end).strip();
        return Arrays.stream(section.split("\n"))
                .map(String::strip)
                .filter(l -> !l.isBlank())
                .collect(Collectors.toList());
    }

    private Map<String, String> parseFieldLine(String line) {
        String cleaned = line.replaceAll("^[\\-\\*•]+\\s*", "").strip();
        Map<String, String> fields = new LinkedHashMap<>();
        for (String part : cleaned.split("\\|")) {
            String[] kv = part.strip().split(":\\s*", 2);
            if (kv.length == 2) {
                fields.put(kv[0].strip().toUpperCase(), kv[1].strip());
            }
        }
        return fields;
    }

    private CvRequest buildFallbackImport(String text, String filename) {
        String titre = filename.replaceAll("\\.(pdf|docx)$", "");
        return CvRequest.builder()
                .titre(titre.isBlank() ? "CV importe" : titre)
                .personalInfo(CvRequest.PersonalInfoDto.builder()
                        .resumeProfessionnel(text.length() > 500 ? text.substring(0, 500) : text)
                        .build())
                .build();
    }
}
