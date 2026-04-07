package com.cvmobile.service;

import com.cvmobile.model.*;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.xwpf.usermodel.*;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.CTShd;
import org.openxmlformats.schemas.wordprocessingml.x2006.main.STShd;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;

/**
 * Genere un CV au format DOCX (Word) — 100% compatible ATS.
 * Structure simple 1 colonne, pas de graphiques, texte pur.
 */
@Slf4j
@Service
public class DocxGenerationService {

    private static final String BLUE = "2563EB";
    private static final String GREY = "6B7280";
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MM/yyyy");

    public byte[] generate(Cv cv) throws IOException {
        try (XWPFDocument doc = new XWPFDocument()) {
            PersonalInfo info = cv.getPersonalInfo();

            // ── NOM ──
            addHeading(doc, formatName(info), 24, true, "000000");

            // ── TITRE POSTE ──
            if (info != null && info.getTitrePoste() != null) {
                addParagraph(doc, info.getTitrePoste(), 14, true, BLUE);
            }

            // ── CONTACT ──
            StringBuilder contact = new StringBuilder();
            if (info != null) {
                if (info.getEmail() != null) contact.append(info.getEmail());
                if (info.getTelephone() != null) {
                    if (!contact.isEmpty()) contact.append("  |  ");
                    contact.append(info.getTelephone());
                }
                if (info.getVille() != null) {
                    if (!contact.isEmpty()) contact.append("  |  ");
                    contact.append(info.getVille());
                    if (info.getPays() != null) contact.append(", ").append(info.getPays());
                }
            }
            if (!contact.isEmpty()) {
                addParagraph(doc, contact.toString(), 10, false, GREY);
            }

            addSeparator(doc);

            // ── PROFIL ──
            if (info != null && info.getResumeProfessionnel() != null
                    && !info.getResumeProfessionnel().isBlank()) {
                addSectionTitle(doc, "PROFIL");
                addParagraph(doc, info.getResumeProfessionnel(), 11, false, "000000");
            }

            // ── COMPETENCES ──
            if (!cv.getSkills().isEmpty()) {
                addSectionTitle(doc, "COMPETENCES");
                StringBuilder skills = new StringBuilder();
                for (Skill s : cv.getSkills()) {
                    if (!skills.isEmpty()) skills.append("  -  ");
                    skills.append(s.getNom());
                }
                addParagraph(doc, skills.toString(), 11, false, "000000");
            }

            // ── LANGUES ──
            if (!cv.getLanguages().isEmpty()) {
                addSectionTitle(doc, "LANGUES");
                StringBuilder langs = new StringBuilder();
                for (Language l : cv.getLanguages()) {
                    if (!langs.isEmpty()) langs.append("  -  ");
                    langs.append(l.getLangue()).append(" (").append(niveauLabel(l.getNiveau())).append(")");
                }
                addParagraph(doc, langs.toString(), 11, false, "000000");
            }

            // ── EXPERIENCES ──
            if (!cv.getExperiences().isEmpty()) {
                addSectionTitle(doc, "EXPERIENCE PROFESSIONNELLE");
                for (Experience exp : cv.getExperiences()) {
                    // Poste + dates
                    String dates = formatDateRange(exp);
                    addJobTitle(doc, exp.getPoste(), dates);
                    // Entreprise + lieu
                    String sub = exp.getEntreprise();
                    if (exp.getLieu() != null) sub += ", " + exp.getLieu();
                    addParagraph(doc, sub, 10, false, GREY);
                    // Description
                    if (exp.getDescription() != null && !exp.getDescription().isBlank()) {
                        for (String line : exp.getDescription().split("\n")) {
                            String trimmed = line.trim();
                            if (trimmed.isEmpty()) continue;
                            if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
                                addBulletPoint(doc, trimmed.substring(2));
                            } else {
                                addParagraph(doc, trimmed, 11, false, "000000");
                            }
                        }
                    }
                    addEmptyLine(doc);
                }
            }

            // ── FORMATIONS ──
            if (!cv.getEducations().isEmpty()) {
                addSectionTitle(doc, "FORMATION");
                for (Education edu : cv.getEducations()) {
                    String dates = formatEduDates(edu);
                    addJobTitle(doc, edu.getDiplome(), dates);
                    if (edu.getEtablissement() != null) {
                        addParagraph(doc, edu.getEtablissement(), 10, false, GREY);
                    }
                }
            }

            // ── CERTIFICATIONS ──
            if (!cv.getCertifications().isEmpty()) {
                addSectionTitle(doc, "CERTIFICATIONS");
                for (Certification cert : cv.getCertifications()) {
                    String date = cert.getDateObtention() != null
                            ? cert.getDateObtention().format(FMT) : "";
                    addJobTitle(doc, cert.getNom(), date);
                    if (cert.getOrganisme() != null) {
                        addParagraph(doc, cert.getOrganisme(), 10, false, GREY);
                    }
                }
            }

            // ── PROJETS ──
            if (!cv.getProjects().isEmpty()) {
                addSectionTitle(doc, "PROJETS");
                for (Project proj : cv.getProjects()) {
                    addParagraph(doc, proj.getNom(), 11, true, "000000");
                    if (proj.getTechnologies() != null) {
                        addParagraph(doc, proj.getTechnologies(), 10, false, GREY);
                    }
                    if (proj.getDescription() != null) {
                        addParagraph(doc, proj.getDescription(), 11, false, "000000");
                    }
                }
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            doc.write(out);
            log.info("DOCX genere pour CV id={}", cv.getId());
            return out.toByteArray();
        }
    }

    // ── Helpers ──────────────────────────────────────────────────

    private String formatName(PersonalInfo info) {
        if (info == null) return "CV";
        return ((info.getPrenom() != null ? info.getPrenom() : "")
                + " " + (info.getNom() != null ? info.getNom() : "")).trim();
    }

    private String formatDateRange(Experience exp) {
        String start = exp.getDateDebut() != null ? exp.getDateDebut().format(FMT) : "";
        if (exp.getActuel() != null && exp.getActuel()) return start + " - Present";
        String end = exp.getDateFin() != null ? exp.getDateFin().format(FMT) : "";
        if (start.equals(end)) return start;
        return start + " - " + end;
    }

    private String formatEduDates(Education edu) {
        String start = edu.getDateDebut() != null ? edu.getDateDebut().format(FMT) : "";
        String end = edu.getDateFin() != null ? edu.getDateFin().format(FMT) : "";
        if (start.equals(end)) return start;
        if (start.isEmpty()) return end;
        return start + " - " + end;
    }

    private String niveauLabel(Language.NiveauLangue niveau) {
        if (niveau == null) return "";
        return switch (niveau) {
            case A1 -> "Debutant";
            case A2 -> "Elementaire";
            case B1 -> "Intermediaire";
            case B2 -> "Avance";
            case C1 -> "Courant";
            case C2 -> "Bilingue";
            case NATIF -> "Langue maternelle";
        };
    }

    private void addHeading(XWPFDocument doc, String text, int size, boolean bold, String color) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingAfter(0);
        XWPFRun run = p.createRun();
        run.setText(text);
        run.setFontSize(size);
        run.setBold(bold);
        run.setColor(color);
        run.setFontFamily("Calibri");
    }

    private void addParagraph(XWPFDocument doc, String text, int size, boolean bold, String color) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingAfter(40);
        XWPFRun run = p.createRun();
        run.setText(text);
        run.setFontSize(size);
        run.setBold(bold);
        run.setColor(color);
        run.setFontFamily("Calibri");
    }

    private void addSectionTitle(XWPFDocument doc, String text) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingBefore(200);
        p.setSpacingAfter(60);
        p.setBorderBottom(Borders.SINGLE);
        XWPFRun run = p.createRun();
        run.setText(text);
        run.setFontSize(12);
        run.setBold(true);
        run.setColor(BLUE);
        run.setFontFamily("Calibri");
        run.setCharacterSpacing(80);
    }

    private void addJobTitle(XWPFDocument doc, String title, String dates) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingAfter(20);
        // Titre
        XWPFRun titleRun = p.createRun();
        titleRun.setText(title);
        titleRun.setFontSize(11);
        titleRun.setBold(true);
        titleRun.setFontFamily("Calibri");
        // Espace + dates
        if (dates != null && !dates.isBlank()) {
            XWPFRun sep = p.createRun();
            sep.setText("    ");
            XWPFRun dateRun = p.createRun();
            dateRun.setText(dates);
            dateRun.setFontSize(10);
            dateRun.setColor(BLUE);
            dateRun.setFontFamily("Calibri");
        }
    }

    private void addBulletPoint(XWPFDocument doc, String text) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingAfter(20);
        p.setIndentationLeft(360);
        XWPFRun bullet = p.createRun();
        bullet.setText("\u2022  ");
        bullet.setFontSize(11);
        bullet.setFontFamily("Calibri");
        XWPFRun run = p.createRun();
        run.setText(text);
        run.setFontSize(11);
        run.setFontFamily("Calibri");
    }

    private void addSeparator(XWPFDocument doc) {
        XWPFParagraph p = doc.createParagraph();
        p.setBorderBottom(Borders.SINGLE);
        p.setSpacingAfter(100);
    }

    private void addEmptyLine(XWPFDocument doc) {
        XWPFParagraph p = doc.createParagraph();
        p.setSpacingAfter(0);
    }
}
