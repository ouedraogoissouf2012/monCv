package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.PdfGenerationException;
import com.cvmobile.model.PdfTemplate;
import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class PdfGenerationService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("MM/yyyy");

    public byte[] generateCvPdf(CvResponse cv, PdfTemplate template) {
        return switch (template) {
            case CLASSIQUE   -> new ClassiqueRenderer().render(cv);
            case MINIMALISTE -> new MinimalisteRenderer().render(cv);
            default          -> new ModerneRenderer().render(cv);
        };
    }

    // ── Shared helpers ────────────────────────────────────────────────────────

    static String buildFullName(CvResponse.PersonalInfoDto info) {
        if (info == null) return "";
        String prenom = info.getPrenom() != null ? info.getPrenom() : "";
        String nom    = info.getNom()    != null ? info.getNom()    : "";
        return (prenom + " " + nom).trim();
    }

    static String buildLocation(CvResponse.PersonalInfoDto info) {
        if (info == null) return null;
        StringBuilder loc = new StringBuilder();
        if (info.getVille() != null) loc.append(info.getVille());
        if (info.getPays()  != null) {
            if (!loc.isEmpty()) loc.append(", ");
            loc.append(info.getPays());
        }
        return loc.isEmpty() ? null : loc.toString();
    }

    static String buildPeriod(String start, String end) {
        if (start == null && end == null) return "";
        if (start == null) return end;
        if (end   == null) return start + " — ...";
        return start + " — " + end;
    }

    static void appendContact(Paragraph p, String value, Font font) {
        if (value == null || value.isBlank()) return;
        if (!p.isEmpty()) p.add(new Chunk("   |   ", font));
        p.add(new Chunk(value, font));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // TEMPLATE 1 — MODERNE  (bleu cobalt, bandeau section, 2 colonnes skills)
    // ══════════════════════════════════════════════════════════════════════════

    private static class ModerneRenderer {

        private static final Color PRIMARY    = new Color(37, 99, 235);
        private static final Color DARK_GRAY  = new Color(55, 65, 81);
        private static final Color MID_GRAY   = new Color(107, 114, 128);

        private static final Font F_NAME    = new Font(Font.HELVETICA, 24, Font.BOLD,   PRIMARY);
        private static final Font F_JOB     = new Font(Font.HELVETICA, 13, Font.NORMAL, MID_GRAY);
        private static final Font F_SECTION = new Font(Font.HELVETICA, 11, Font.BOLD,   Color.WHITE);
        private static final Font F_ITEM    = new Font(Font.HELVETICA, 11, Font.BOLD,   DARK_GRAY);
        private static final Font F_SUB     = new Font(Font.HELVETICA, 10, Font.ITALIC, MID_GRAY);
        private static final Font F_BODY    = new Font(Font.HELVETICA, 10, Font.NORMAL, DARK_GRAY);
        private static final Font F_CONTACT = new Font(Font.HELVETICA,  9, Font.NORMAL, MID_GRAY);

        byte[] render(CvResponse cv) {
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
                throw new PdfGenerationException("Erreur PDF MODERNE", e);
            }
        }

        private void addHeader(Document doc, CvResponse cv) throws DocumentException {
            CvResponse.PersonalInfoDto info = cv.getPersonalInfo();
            String fullName = buildFullName(info);
            if (!fullName.isBlank()) {
                Paragraph p = new Paragraph(fullName, F_NAME);
                p.setSpacingAfter(4);
                doc.add(p);
            }
            if (info != null && info.getTitrePoste() != null) {
                Paragraph p = new Paragraph(info.getTitrePoste(), F_JOB);
                p.setSpacingAfter(8);
                doc.add(p);
            }
            if (info != null) {
                Paragraph contact = new Paragraph();
                appendContact(contact, info.getEmail(), F_CONTACT);
                appendContact(contact, info.getTelephone(), F_CONTACT);
                appendContact(contact, buildLocation(info), F_CONTACT);
                appendContact(contact, info.getLinkedIn(), F_CONTACT);
                appendContact(contact, info.getPortfolio(), F_CONTACT);
                contact.setSpacingAfter(12);
                doc.add(contact);
            }
        }

        private void addSummary(Document doc, CvResponse cv) throws DocumentException {
            if (cv.getPersonalInfo() == null) return;
            String s = cv.getPersonalInfo().getResumeProfessionnel();
            if (s == null || s.isBlank()) return;
            sectionTitle(doc, "RÉSUMÉ PROFESSIONNEL");
            Paragraph p = new Paragraph(s, F_BODY);
            p.setSpacingAfter(12);
            doc.add(p);
        }

        private void addExperiences(Document doc, CvResponse cv) throws DocumentException {
            List<CvResponse.ExperienceDto> list = cv.getExperiences();
            if (list == null || list.isEmpty()) return;
            sectionTitle(doc, "EXPÉRIENCES PROFESSIONNELLES");
            for (CvResponse.ExperienceDto exp : list) {
                Paragraph line = new Paragraph();
                if (exp.getPoste()      != null) line.add(new Chunk(exp.getPoste(), F_ITEM));
                if (exp.getEntreprise() != null) line.add(new Chunk("  •  " + exp.getEntreprise(), F_BODY));
                doc.add(line);
                String period = buildPeriod(
                        exp.getDateDebut() != null ? exp.getDateDebut().format(DATE_FMT) : null,
                        Boolean.TRUE.equals(exp.getActuel()) ? "Présent"
                                : (exp.getDateFin() != null ? exp.getDateFin().format(DATE_FMT) : null));
                if (exp.getLieu() != null) period += "  |  " + exp.getLieu();
                doc.add(new Paragraph(period, F_SUB));
                if (exp.getDescription() != null && !exp.getDescription().isBlank()) {
                    Paragraph desc = new Paragraph(exp.getDescription(), F_BODY);
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
            sectionTitle(doc, "FORMATIONS");
            for (CvResponse.EducationDto edu : list) {
                Paragraph line = new Paragraph();
                if (edu.getDiplome()       != null) line.add(new Chunk(edu.getDiplome(), F_ITEM));
                if (edu.getEtablissement() != null) line.add(new Chunk("  •  " + edu.getEtablissement(), F_BODY));
                if (edu.getDomaine()       != null) line.add(new Chunk("  —  " + edu.getDomaine(), F_SUB));
                doc.add(line);
                String period = buildPeriod(
                        edu.getDateDebut() != null ? edu.getDateDebut().format(DATE_FMT) : null,
                        edu.getDateFin()   != null ? edu.getDateFin().format(DATE_FMT)   : null);
                Paragraph sub = new Paragraph(period, F_SUB);
                sub.setSpacingAfter(8);
                doc.add(sub);
                if (edu.getDescription() != null && !edu.getDescription().isBlank()) {
                    Paragraph desc = new Paragraph(edu.getDescription(), F_BODY);
                    desc.setIndentationLeft(10);
                    desc.setSpacingAfter(8);
                    doc.add(desc);
                }
            }
        }

        private void addSkills(Document doc, CvResponse cv) throws DocumentException {
            List<CvResponse.SkillDto> list = cv.getSkills();
            if (list == null || list.isEmpty()) return;
            sectionTitle(doc, "COMPÉTENCES");
            PdfPTable table = new PdfPTable(2);
            table.setWidthPercentage(100);
            table.setSpacingAfter(12);
            for (CvResponse.SkillDto skill : list) {
                PdfPCell cell = new PdfPCell();
                cell.setBorder(Rectangle.NO_BORDER);
                cell.setPaddingBottom(5);
                Paragraph p = new Paragraph();
                if (skill.getNom() != null) p.add(new Chunk(skill.getNom(), F_BODY));
                if (skill.getNiveau() != null) {
                    int n = skill.getNiveau();
                    StringBuilder bars = new StringBuilder("  ");
                    for (int i = 1; i <= 5; i++) bars.append(i <= n ? "●" : "○");
                    p.add(new Chunk(bars.toString(),
                            new Font(Font.HELVETICA, 9, Font.NORMAL, PRIMARY)));
                }
                cell.addElement(p);
                table.addCell(cell);
            }
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
            sectionTitle(doc, "LANGUES");
            PdfPTable table = new PdfPTable(3);
            table.setWidthPercentage(60);
            table.setSpacingAfter(12);
            for (CvResponse.LanguageDto lang : list) {
                PdfPCell cell = new PdfPCell();
                cell.setBorder(Rectangle.NO_BORDER);
                cell.setPaddingBottom(5);
                Paragraph p = new Paragraph();
                if (lang.getLangue() != null) p.add(new Chunk(lang.getLangue(), F_BODY));
                if (lang.getNiveau() != null)
                    p.add(new Chunk("  " + lang.getNiveau(), F_SUB));
                cell.addElement(p);
                table.addCell(cell);
            }
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

        private void sectionTitle(Document doc, String title) throws DocumentException {
            PdfPTable t = new PdfPTable(1);
            t.setWidthPercentage(100);
            t.setSpacingBefore(8);
            t.setSpacingAfter(6);
            PdfPCell cell = new PdfPCell(new Phrase(title, F_SECTION));
            cell.setBackgroundColor(PRIMARY);
            cell.setPadding(5);
            cell.setBorder(Rectangle.NO_BORDER);
            t.addCell(cell);
            doc.add(t);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // TEMPLATE 2 — CLASSIQUE  (noir & blanc, filet de séparation, ATS-friendly)
    // ══════════════════════════════════════════════════════════════════════════

    private static class ClassiqueRenderer {

        private static final Color BLACK     = new Color(17, 24, 39);
        private static final Color DARK      = new Color(55, 65, 81);
        private static final Color GRAY      = new Color(107, 114, 128);
        private static final Color LIGHT     = new Color(229, 231, 235);

        private static final Font F_NAME    = new Font(Font.HELVETICA, 26, Font.BOLD,   BLACK);
        private static final Font F_JOB     = new Font(Font.HELVETICA, 12, Font.NORMAL, GRAY);
        private static final Font F_SECTION = new Font(Font.HELVETICA, 11, Font.BOLD,   BLACK);
        private static final Font F_ITEM    = new Font(Font.HELVETICA, 11, Font.BOLD,   DARK);
        private static final Font F_SUB     = new Font(Font.HELVETICA, 10, Font.ITALIC, GRAY);
        private static final Font F_BODY    = new Font(Font.HELVETICA, 10, Font.NORMAL, DARK);
        private static final Font F_CONTACT = new Font(Font.HELVETICA,  9, Font.NORMAL, GRAY);

        byte[] render(CvResponse cv) {
            try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                Document doc = new Document(PageSize.A4, 50, 50, 50, 50);
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
                throw new PdfGenerationException("Erreur PDF CLASSIQUE", e);
            }
        }

        private void addHeader(Document doc, CvResponse cv) throws DocumentException {
            CvResponse.PersonalInfoDto info = cv.getPersonalInfo();
            String fullName = buildFullName(info);
            if (!fullName.isBlank()) {
                Paragraph p = new Paragraph(fullName, F_NAME);
                p.setAlignment(Element.ALIGN_CENTER);
                p.setSpacingAfter(4);
                doc.add(p);
            }
            if (info != null && info.getTitrePoste() != null) {
                Paragraph p = new Paragraph(info.getTitrePoste(), F_JOB);
                p.setAlignment(Element.ALIGN_CENTER);
                p.setSpacingAfter(8);
                doc.add(p);
            }
            // Thin divider
            addHRule(doc, LIGHT, 1f, 4f, 8f);
            if (info != null) {
                Paragraph contact = new Paragraph();
                contact.setAlignment(Element.ALIGN_CENTER);
                appendContact(contact, info.getEmail(), F_CONTACT);
                appendContact(contact, info.getTelephone(), F_CONTACT);
                appendContact(contact, buildLocation(info), F_CONTACT);
                appendContact(contact, info.getLinkedIn(), F_CONTACT);
                contact.setSpacingAfter(14);
                doc.add(contact);
            }
        }

        private void addSummary(Document doc, CvResponse cv) throws DocumentException {
            if (cv.getPersonalInfo() == null) return;
            String s = cv.getPersonalInfo().getResumeProfessionnel();
            if (s == null || s.isBlank()) return;
            sectionTitle(doc, "PROFIL");
            Paragraph p = new Paragraph(s, F_BODY);
            p.setSpacingAfter(12);
            doc.add(p);
        }

        private void addExperiences(Document doc, CvResponse cv) throws DocumentException {
            List<CvResponse.ExperienceDto> list = cv.getExperiences();
            if (list == null || list.isEmpty()) return;
            sectionTitle(doc, "EXPÉRIENCES PROFESSIONNELLES");
            for (CvResponse.ExperienceDto exp : list) {
                // Poste + entreprise sur une ligne, dates à droite
                PdfPTable row = new PdfPTable(new float[]{7, 3});
                row.setWidthPercentage(100);
                row.setSpacingBefore(4);

                PdfPCell left = new PdfPCell();
                left.setBorder(Rectangle.NO_BORDER);
                Paragraph pLeft = new Paragraph();
                if (exp.getPoste() != null) pLeft.add(new Chunk(exp.getPoste(), F_ITEM));
                if (exp.getEntreprise() != null)
                    pLeft.add(new Chunk("  —  " + exp.getEntreprise(), F_BODY));
                left.addElement(pLeft);
                row.addCell(left);

                PdfPCell right = new PdfPCell();
                right.setBorder(Rectangle.NO_BORDER);
                right.setHorizontalAlignment(Element.ALIGN_RIGHT);
                String period = buildPeriod(
                        exp.getDateDebut() != null ? exp.getDateDebut().format(DATE_FMT) : null,
                        Boolean.TRUE.equals(exp.getActuel()) ? "Présent"
                                : (exp.getDateFin() != null ? exp.getDateFin().format(DATE_FMT) : null));
                right.addElement(new Paragraph(period, F_SUB));
                row.addCell(right);
                doc.add(row);

                if (exp.getLieu() != null) {
                    doc.add(new Paragraph(exp.getLieu(), F_SUB));
                }
                if (exp.getDescription() != null && !exp.getDescription().isBlank()) {
                    Paragraph desc = new Paragraph(exp.getDescription(), F_BODY);
                    desc.setIndentationLeft(8);
                    desc.setSpacingAfter(10);
                    doc.add(desc);
                } else {
                    doc.add(new Paragraph(" "));
                }
            }
        }

        private void addEducations(Document doc, CvResponse cv) throws DocumentException {
            List<CvResponse.EducationDto> list = cv.getEducations();
            if (list == null || list.isEmpty()) return;
            sectionTitle(doc, "FORMATIONS");
            for (CvResponse.EducationDto edu : list) {
                PdfPTable row = new PdfPTable(new float[]{7, 3});
                row.setWidthPercentage(100);
                row.setSpacingBefore(4);

                PdfPCell left = new PdfPCell();
                left.setBorder(Rectangle.NO_BORDER);
                Paragraph pLeft = new Paragraph();
                if (edu.getDiplome() != null) pLeft.add(new Chunk(edu.getDiplome(), F_ITEM));
                if (edu.getEtablissement() != null)
                    pLeft.add(new Chunk("  —  " + edu.getEtablissement(), F_BODY));
                left.addElement(pLeft);
                row.addCell(left);

                PdfPCell right = new PdfPCell();
                right.setBorder(Rectangle.NO_BORDER);
                right.setHorizontalAlignment(Element.ALIGN_RIGHT);
                String period = buildPeriod(
                        edu.getDateDebut() != null ? edu.getDateDebut().format(DATE_FMT) : null,
                        edu.getDateFin()   != null ? edu.getDateFin().format(DATE_FMT)   : null);
                right.addElement(new Paragraph(period, F_SUB));
                row.addCell(right);
                doc.add(row);

                if (edu.getDomaine() != null) {
                    doc.add(new Paragraph(edu.getDomaine(), F_SUB));
                }
                if (edu.getDescription() != null && !edu.getDescription().isBlank()) {
                    Paragraph desc = new Paragraph(edu.getDescription(), F_BODY);
                    desc.setIndentationLeft(8);
                    desc.setSpacingAfter(10);
                    doc.add(desc);
                } else {
                    doc.add(new Paragraph(" "));
                }
            }
        }

        private void addSkills(Document doc, CvResponse cv) throws DocumentException {
            List<CvResponse.SkillDto> list = cv.getSkills();
            if (list == null || list.isEmpty()) return;
            sectionTitle(doc, "COMPÉTENCES");
            PdfPTable table = new PdfPTable(3);
            table.setWidthPercentage(100);
            table.setSpacingAfter(12);
            for (CvResponse.SkillDto skill : list) {
                PdfPCell cell = new PdfPCell();
                cell.setBorder(Rectangle.LEFT);
                cell.setBorderColor(LIGHT);
                cell.setPaddingLeft(6);
                cell.setPaddingBottom(5);
                Paragraph p = new Paragraph();
                if (skill.getNom() != null) p.add(new Chunk(skill.getNom(), F_BODY));
                if (skill.getCategorie() != null)
                    p.add(new Chunk("\n" + skill.getCategorie(), F_SUB));
                cell.addElement(p);
                table.addCell(cell);
            }
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

        private void addLanguages(Document doc, CvResponse cv) throws DocumentException {
            List<CvResponse.LanguageDto> list = cv.getLanguages();
            if (list == null || list.isEmpty()) return;
            sectionTitle(doc, "LANGUES");
            Paragraph p = new Paragraph();
            for (int i = 0; i < list.size(); i++) {
                CvResponse.LanguageDto lang = list.get(i);
                String entry = lang.getLangue() != null ? lang.getLangue() : "";
                if (lang.getNiveau() != null) entry += " (" + lang.getNiveau() + ")";
                if (i < list.size() - 1) entry += "    ";
                p.add(new Chunk(entry, F_BODY));
            }
            p.setSpacingAfter(12);
            doc.add(p);
        }

        private void sectionTitle(Document doc, String title) throws DocumentException {
            addHRule(doc, LIGHT, 1f, 10f, 4f);
            Paragraph p = new Paragraph(title, F_SECTION);
            p.setSpacingAfter(6);
            doc.add(p);
        }

        private void addHRule(Document doc, Color color, float thickness,
                              float spacingBefore, float spacingAfter) throws DocumentException {
            PdfPTable rule = new PdfPTable(1);
            rule.setWidthPercentage(100);
            rule.setSpacingBefore(spacingBefore);
            rule.setSpacingAfter(spacingAfter);
            PdfPCell cell = new PdfPCell();
            cell.setBorder(Rectangle.BOTTOM);
            cell.setBorderColor(color);
            cell.setBorderWidth(thickness);
            cell.setPadding(0);
            cell.setFixedHeight(0);
            rule.addCell(cell);
            doc.add(rule);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // TEMPLATE 3 — MINIMALISTE  (sidebar foncée + colonne principale épurée)
    // ══════════════════════════════════════════════════════════════════════════

    private static class MinimalisteRenderer {

        private static final Color SIDEBAR_BG  = new Color(30, 41, 59);   // slate-800
        private static final Color ACCENT      = new Color(99, 102, 241);  // indigo-500
        private static final Color SIDEBAR_TXT = new Color(226, 232, 240); // slate-200
        private static final Color SIDEBAR_MUT = new Color(148, 163, 184); // slate-400
        private static final Color BODY_DARK   = new Color(15, 23, 42);    // slate-900
        private static final Color BODY_MED    = new Color(71, 85, 105);   // slate-600
        private static final Color BODY_LIGHT  = new Color(203, 213, 225); // slate-300

        private static final Font F_SB_NAME    = new Font(Font.HELVETICA, 18, Font.BOLD,   Color.WHITE);
        private static final Font F_SB_JOB     = new Font(Font.HELVETICA, 10, Font.NORMAL, SIDEBAR_MUT);
        private static final Font F_SB_SECTION = new Font(Font.HELVETICA, 9,  Font.BOLD,   ACCENT);
        private static final Font F_SB_BODY    = new Font(Font.HELVETICA, 9,  Font.NORMAL, SIDEBAR_TXT);
        private static final Font F_SB_MUT     = new Font(Font.HELVETICA, 8,  Font.NORMAL, SIDEBAR_MUT);

        private static final Font F_SECTION    = new Font(Font.HELVETICA, 10, Font.BOLD,   ACCENT);
        private static final Font F_ITEM       = new Font(Font.HELVETICA, 11, Font.BOLD,   BODY_DARK);
        private static final Font F_SUB        = new Font(Font.HELVETICA, 9,  Font.ITALIC, BODY_MED);
        private static final Font F_BODY       = new Font(Font.HELVETICA, 10, Font.NORMAL, BODY_DARK);

        byte[] render(CvResponse cv) {
            try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
                Document doc = new Document(PageSize.A4, 0, 0, 0, 0);
                PdfWriter.getInstance(doc, out);
                doc.open();

                // Outer table: sidebar (30%) | main (70%)
                PdfPTable outer = new PdfPTable(new float[]{3f, 7f});
                outer.setWidthPercentage(100);
                outer.setExtendLastRow(true);

                PdfPCell sidebar = buildSidebar(cv);
                PdfPCell main    = buildMain(cv);

                outer.addCell(sidebar);
                outer.addCell(main);
                doc.add(outer);

                doc.close();
                return out.toByteArray();
            } catch (Exception e) {
                throw new PdfGenerationException("Erreur PDF MINIMALISTE", e);
            }
        }

        private PdfPCell buildSidebar(CvResponse cv) throws DocumentException {
            PdfPCell sidebar = new PdfPCell();
            sidebar.setBackgroundColor(SIDEBAR_BG);
            sidebar.setPadding(20);
            sidebar.setBorder(Rectangle.NO_BORDER);

            CvResponse.PersonalInfoDto info = cv.getPersonalInfo();

            // Nom
            String fullName = buildFullName(info);
            if (!fullName.isBlank()) {
                Paragraph p = new Paragraph(fullName, F_SB_NAME);
                p.setSpacingAfter(4);
                sidebar.addElement(p);
            }
            if (info != null && info.getTitrePoste() != null) {
                Paragraph p = new Paragraph(info.getTitrePoste(), F_SB_JOB);
                p.setSpacingAfter(16);
                sidebar.addElement(p);
            }

            // Contact
            if (info != null) {
                sbSection(sidebar, "CONTACT");
                sbLine(sidebar, info.getEmail());
                sbLine(sidebar, info.getTelephone());
                sbLine(sidebar, buildLocation(info));
                sbLine(sidebar, info.getLinkedIn());
                sbLine(sidebar, info.getPortfolio());
                sidebar.addElement(new Paragraph(" "));
            }

            // Compétences
            List<CvResponse.SkillDto> skills = cv.getSkills();
            if (skills != null && !skills.isEmpty()) {
                sbSection(sidebar, "COMPÉTENCES");
                for (CvResponse.SkillDto skill : skills) {
                    if (skill.getNom() == null) continue;
                    Paragraph p = new Paragraph(skill.getNom(), F_SB_BODY);
                    if (skill.getNiveau() != null) {
                        int n = skill.getNiveau();
                        StringBuilder dots = new StringBuilder("  ");
                        for (int i = 1; i <= 5; i++) dots.append(i <= n ? "●" : "○");
                        p.add(new Chunk(dots.toString(),
                                new Font(Font.HELVETICA, 8, Font.NORMAL, ACCENT)));
                    }
                    p.setSpacingAfter(3);
                    sidebar.addElement(p);
                }
                sidebar.addElement(new Paragraph(" "));
            }

            // Langues
            List<CvResponse.LanguageDto> langs = cv.getLanguages();
            if (langs != null && !langs.isEmpty()) {
                sbSection(sidebar, "LANGUES");
                for (CvResponse.LanguageDto lang : langs) {
                    if (lang.getLangue() == null) continue;
                    String entry = lang.getLangue();
                    if (lang.getNiveau() != null) entry += " — " + lang.getNiveau();
                    Paragraph p = new Paragraph(entry, F_SB_BODY);
                    p.setSpacingAfter(3);
                    sidebar.addElement(p);
                }
            }

            return sidebar;
        }

        private PdfPCell buildMain(CvResponse cv) throws DocumentException {
            PdfPCell main = new PdfPCell();
            main.setBackgroundColor(Color.WHITE);
            main.setPaddingLeft(24);
            main.setPaddingRight(24);
            main.setPaddingTop(24);
            main.setPaddingBottom(24);
            main.setBorder(Rectangle.NO_BORDER);

            // Résumé
            CvResponse.PersonalInfoDto info = cv.getPersonalInfo();
            if (info != null && info.getResumeProfessionnel() != null
                    && !info.getResumeProfessionnel().isBlank()) {
                mainSection(main, "À PROPOS");
                Paragraph p = new Paragraph(info.getResumeProfessionnel(), F_BODY);
                p.setSpacingAfter(14);
                main.addElement(p);
            }

            // Expériences
            List<CvResponse.ExperienceDto> experiences = cv.getExperiences();
            if (experiences != null && !experiences.isEmpty()) {
                mainSection(main, "EXPÉRIENCES");
                for (CvResponse.ExperienceDto exp : experiences) {
                    Paragraph line = new Paragraph();
                    if (exp.getPoste() != null) line.add(new Chunk(exp.getPoste(), F_ITEM));
                    main.addElement(line);

                    String sub = "";
                    if (exp.getEntreprise() != null) sub += exp.getEntreprise();
                    String period = buildPeriod(
                            exp.getDateDebut() != null ? exp.getDateDebut().format(DATE_FMT) : null,
                            Boolean.TRUE.equals(exp.getActuel()) ? "Présent"
                                    : (exp.getDateFin() != null ? exp.getDateFin().format(DATE_FMT) : null));
                    if (!period.isBlank()) sub += (sub.isEmpty() ? "" : "  •  ") + period;
                    if (exp.getLieu() != null) sub += "  •  " + exp.getLieu();
                    if (!sub.isBlank()) main.addElement(new Paragraph(sub, F_SUB));

                    if (exp.getDescription() != null && !exp.getDescription().isBlank()) {
                        Paragraph desc = new Paragraph(exp.getDescription(), F_BODY);
                        desc.setIndentationLeft(8);
                        desc.setSpacingAfter(10);
                        main.addElement(desc);
                    } else {
                        main.addElement(new Paragraph(" "));
                    }
                }
            }

            // Formations
            List<CvResponse.EducationDto> educations = cv.getEducations();
            if (educations != null && !educations.isEmpty()) {
                mainSection(main, "FORMATIONS");
                for (CvResponse.EducationDto edu : educations) {
                    Paragraph line = new Paragraph();
                    if (edu.getDiplome() != null) line.add(new Chunk(edu.getDiplome(), F_ITEM));
                    main.addElement(line);

                    String sub = "";
                    if (edu.getEtablissement() != null) sub += edu.getEtablissement();
                    if (edu.getDomaine() != null) sub += (sub.isEmpty() ? "" : "  —  ") + edu.getDomaine();
                    String period = buildPeriod(
                            edu.getDateDebut() != null ? edu.getDateDebut().format(DATE_FMT) : null,
                            edu.getDateFin()   != null ? edu.getDateFin().format(DATE_FMT)   : null);
                    if (!period.isBlank()) sub += (sub.isEmpty() ? "" : "  •  ") + period;
                    if (!sub.isBlank()) {
                        Paragraph subP = new Paragraph(sub, F_SUB);
                        subP.setSpacingAfter(8);
                        main.addElement(subP);
                    }
                    if (edu.getDescription() != null && !edu.getDescription().isBlank()) {
                        Paragraph desc = new Paragraph(edu.getDescription(), F_BODY);
                        desc.setIndentationLeft(8);
                        desc.setSpacingAfter(10);
                        main.addElement(desc);
                    }
                }
            }

            return main;
        }

        private void sbSection(PdfPCell cell, String title) {
            Paragraph p = new Paragraph(title, F_SB_SECTION);
            p.setSpacingBefore(8);
            p.setSpacingAfter(5);
            cell.addElement(p);
        }

        private void sbLine(PdfPCell cell, String value) {
            if (value == null || value.isBlank()) return;
            Paragraph p = new Paragraph(value, F_SB_BODY);
            p.setSpacingAfter(3);
            cell.addElement(p);
        }

        private void mainSection(PdfPCell cell, String title) {
            Paragraph p = new Paragraph(title, F_SECTION);
            p.setSpacingBefore(6);
            p.setSpacingAfter(8);
            cell.addElement(p);
        }
    }
}
