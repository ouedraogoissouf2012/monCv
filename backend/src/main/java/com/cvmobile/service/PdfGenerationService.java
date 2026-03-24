package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class PdfGenerationService {

    private static final Color PRIMARY   = new Color(37, 99, 235);   // #2563EB
    private static final Color DARK_GRAY = new Color(55, 65, 81);
    private static final Color LIGHT_GRAY= new Color(243, 244, 246);
    private static final Color MID_GRAY  = new Color(107, 114, 128);

    private static final Font FONT_NAME    = new Font(Font.HELVETICA, 24, Font.BOLD,   PRIMARY);
    private static final Font FONT_TITLE   = new Font(Font.HELVETICA, 13, Font.NORMAL, MID_GRAY);
    private static final Font FONT_SECTION = new Font(Font.HELVETICA, 11, Font.BOLD,   Color.WHITE);
    private static final Font FONT_ITEM    = new Font(Font.HELVETICA, 11, Font.BOLD,   DARK_GRAY);
    private static final Font FONT_SUB     = new Font(Font.HELVETICA, 10, Font.ITALIC, MID_GRAY);
    private static final Font FONT_BODY    = new Font(Font.HELVETICA, 10, Font.NORMAL, DARK_GRAY);
    private static final Font FONT_CONTACT = new Font(Font.HELVETICA,  9, Font.NORMAL, MID_GRAY);

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("MM/yyyy");

    public byte[] generateCvPdf(CvResponse cv) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document doc = new Document(PageSize.A4, 40, 40, 40, 40);
            PdfWriter.getInstance(doc, out);
            doc.open();

            addHeader(doc, cv);
            addSummary(doc, cv);
            addExperiences(doc, cv);
            addEducations(doc, cv);
            addSkills(doc, cv);
            addLanguages(doc, cv);

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Erreur lors de la génération du PDF", e);
        }
    }

    private void addHeader(Document doc, CvResponse cv) throws DocumentException {
        CvResponse.PersonalInfoDto info = cv.getPersonalInfo();

        // Nom complet
        String fullName = buildFullName(info);
        if (!fullName.isBlank()) {
            Paragraph name = new Paragraph(fullName, FONT_NAME);
            name.setSpacingAfter(4);
            doc.add(name);
        }

        // Titre du poste
        if (info != null && info.getTitrePoste() != null) {
            Paragraph jobTitle = new Paragraph(info.getTitrePoste(), FONT_TITLE);
            jobTitle.setSpacingAfter(8);
            doc.add(jobTitle);
        }

        // Ligne de séparation bleue
        doc.add(buildSeparator(PRIMARY, 2f, 6f));

        // Infos de contact sur une ligne
        if (info != null) {
            Paragraph contact = new Paragraph();
            contact.setFont(FONT_CONTACT);
            appendContact(contact, info.getEmail());
            appendContact(contact, info.getTelephone());
            appendContact(contact, buildLocation(info));
            appendContact(contact, info.getLinkedIn());
            appendContact(contact, info.getPortfolio());
            contact.setSpacingAfter(12);
            doc.add(contact);
        }
    }

    private void addSummary(Document doc, CvResponse cv) throws DocumentException {
        if (cv.getPersonalInfo() == null) return;
        String summary = cv.getPersonalInfo().getResumeProfessionnel();
        if (summary == null || summary.isBlank()) return;

        addSectionTitle(doc, "RÉSUMÉ PROFESSIONNEL");
        Paragraph p = new Paragraph(summary, FONT_BODY);
        p.setSpacingAfter(12);
        doc.add(p);
    }

    private void addExperiences(Document doc, CvResponse cv) throws DocumentException {
        List<CvResponse.ExperienceDto> list = cv.getExperiences();
        if (list == null || list.isEmpty()) return;

        addSectionTitle(doc, "EXPÉRIENCES PROFESSIONNELLES");
        for (CvResponse.ExperienceDto exp : list) {
            // Poste - Entreprise
            Paragraph line1 = new Paragraph();
            if (exp.getPoste() != null)      line1.add(new Chunk(exp.getPoste(), FONT_ITEM));
            if (exp.getEntreprise() != null) line1.add(new Chunk("  •  " + exp.getEntreprise(), FONT_BODY));
            doc.add(line1);

            // Dates + lieu
            String period = buildPeriod(
                    exp.getDateDebut() != null ? exp.getDateDebut().format(DATE_FMT) : null,
                    Boolean.TRUE.equals(exp.getActuel()) ? "Présent" : (exp.getDateFin() != null ? exp.getDateFin().format(DATE_FMT) : null)
            );
            if (exp.getLieu() != null) period += "  |  " + exp.getLieu();
            doc.add(new Paragraph(period, FONT_SUB));

            // Description
            if (exp.getDescription() != null && !exp.getDescription().isBlank()) {
                Paragraph desc = new Paragraph(exp.getDescription(), FONT_BODY);
                desc.setIndentationLeft(10);
                desc.setSpacingAfter(8);
                doc.add(desc);
            } else {
                doc.add(Chunk.NEWLINE);
            }
        }
    }

    private void addEducations(Document doc, CvResponse cv) throws DocumentException {
        List<CvResponse.EducationDto> list = cv.getEducations();
        if (list == null || list.isEmpty()) return;

        addSectionTitle(doc, "FORMATIONS");
        for (CvResponse.EducationDto edu : list) {
            Paragraph line1 = new Paragraph();
            if (edu.getDiplome() != null)        line1.add(new Chunk(edu.getDiplome(), FONT_ITEM));
            if (edu.getEtablissement() != null)  line1.add(new Chunk("  •  " + edu.getEtablissement(), FONT_BODY));
            if (edu.getDomaine() != null)        line1.add(new Chunk("  —  " + edu.getDomaine(), FONT_SUB));
            doc.add(line1);

            String period = buildPeriod(
                    edu.getDateDebut() != null ? edu.getDateDebut().format(DATE_FMT) : null,
                    edu.getDateFin()   != null ? edu.getDateFin().format(DATE_FMT)   : null
            );
            Paragraph sub = new Paragraph(period, FONT_SUB);
            sub.setSpacingAfter(edu.getDescription() != null ? 2 : 8);
            doc.add(sub);

            if (edu.getDescription() != null && !edu.getDescription().isBlank()) {
                Paragraph desc = new Paragraph(edu.getDescription(), FONT_BODY);
                desc.setIndentationLeft(10);
                desc.setSpacingAfter(8);
                doc.add(desc);
            }
        }
    }

    private void addSkills(Document doc, CvResponse cv) throws DocumentException {
        List<CvResponse.SkillDto> list = cv.getSkills();
        if (list == null || list.isEmpty()) return;

        addSectionTitle(doc, "COMPÉTENCES");

        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setSpacingAfter(12);

        for (CvResponse.SkillDto skill : list) {
            PdfPCell cell = new PdfPCell();
            cell.setBorder(Rectangle.NO_BORDER);
            cell.setPaddingBottom(5);

            Paragraph p = new Paragraph();
            if (skill.getNom() != null) p.add(new Chunk(skill.getNom(), FONT_BODY));
            if (skill.getCategorie() != null)
                p.add(new Chunk("  (" + skill.getCategorie() + ")", FONT_SUB));

            // Barres de niveau (●●●●○ sur 5)
            if (skill.getNiveau() != null) {
                int n = skill.getNiveau();
                StringBuilder bars = new StringBuilder("  ");
                for (int i = 1; i <= 5; i++) bars.append(i <= n ? "●" : "○");
                p.add(new Chunk(bars.toString(), new Font(Font.HELVETICA, 9, Font.NORMAL, PRIMARY)));
            }
            cell.addElement(p);
            table.addCell(cell);
        }
        // Compléter la dernière ligne si nombre impair
        if (list.size() % 2 != 0) {
            PdfPCell empty = new PdfPCell();
            empty.setBorder(Rectangle.NO_BORDER);
            table.addCell(empty);
        }
        doc.add(table);
    }

    private void addLanguages(Document doc, CvResponse cv) throws DocumentException {
        List<CvResponse.LanguageDto> list = cv.getLanguages();
        if (list == null || list.isEmpty()) return;

        addSectionTitle(doc, "LANGUES");

        PdfPTable table = new PdfPTable(3);
        table.setWidthPercentage(60);
        table.setSpacingAfter(12);

        for (CvResponse.LanguageDto lang : list) {
            PdfPCell cell = new PdfPCell();
            cell.setBorder(Rectangle.NO_BORDER);
            cell.setPaddingBottom(5);

            Paragraph p = new Paragraph();
            if (lang.getLangue() != null) p.add(new Chunk(lang.getLangue(), FONT_BODY));
            if (lang.getNiveau()  != null) p.add(new Chunk("  " + lang.getNiveau(), FONT_SUB));
            cell.addElement(p);
            table.addCell(cell);
        }
        // Compléter la dernière ligne
        int rem = list.size() % 3;
        if (rem != 0) {
            for (int i = 0; i < 3 - rem; i++) {
                PdfPCell empty = new PdfPCell();
                empty.setBorder(Rectangle.NO_BORDER);
                table.addCell(empty);
            }
        }
        doc.add(table);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private void addSectionTitle(Document doc, String title) throws DocumentException {
        PdfPTable header = new PdfPTable(1);
        header.setWidthPercentage(100);
        header.setSpacingBefore(8);
        header.setSpacingAfter(6);

        PdfPCell cell = new PdfPCell(new Phrase(title, FONT_SECTION));
        cell.setBackgroundColor(PRIMARY);
        cell.setPadding(5);
        cell.setBorder(Rectangle.NO_BORDER);
        header.addCell(cell);
        doc.add(header);
    }

    private Paragraph buildSeparator(Color color, float thickness, float spacing) {
        Paragraph sep = new Paragraph(" ");
        sep.setSpacingBefore(spacing);
        return sep;
    }

    private String buildFullName(CvResponse.PersonalInfoDto info) {
        if (info == null) return "";
        String nom    = info.getNom()    != null ? info.getNom()    : "";
        String prenom = info.getPrenom() != null ? info.getPrenom() : "";
        return (prenom + " " + nom).trim();
    }

    private String buildLocation(CvResponse.PersonalInfoDto info) {
        if (info == null) return null;
        StringBuilder loc = new StringBuilder();
        if (info.getVille()  != null) loc.append(info.getVille());
        if (info.getPays()   != null) {
            if (!loc.isEmpty()) loc.append(", ");
            loc.append(info.getPays());
        }
        return loc.isEmpty() ? null : loc.toString();
    }

    private String buildPeriod(String start, String end) {
        if (start == null && end == null) return "";
        if (start == null) return end;
        if (end   == null) return start + " — ...";
        return start + " — " + end;
    }

    private void appendContact(Paragraph p, String value) {
        if (value == null || value.isBlank()) return;
        if (!p.isEmpty()) p.add(new Chunk("   |   ", FONT_CONTACT));
        p.add(new Chunk(value, FONT_CONTACT));
    }
}
