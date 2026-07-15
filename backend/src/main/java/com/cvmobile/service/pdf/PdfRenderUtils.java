package com.cvmobile.service.pdf;

import com.cvmobile.dto.CvResponse;
import com.lowagie.text.Chunk;
import com.lowagie.text.Font;
import com.lowagie.text.Paragraph;

import java.time.format.DateTimeFormatter;

public final class PdfRenderUtils {

    public static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("MM/yyyy");

    private PdfRenderUtils() {
    }

    public static String fullName(CvResponse.PersonalInfoDto info) {
        if (info == null) return "";
        return ((info.getPrenom() == null ? "" : info.getPrenom()) + " "
                + (info.getNom() == null ? "" : info.getNom())).trim();
    }

    public static String location(CvResponse.PersonalInfoDto info) {
        if (info == null) return null;
        return joinNonBlank(", ", info.getVille(), info.getPays());
    }

    public static String period(String start, String end) {
        if (start == null && end == null) return "";
        if (start == null) return end;
        if (end == null) return start + " — ...";
        return start + " — " + end;
    }

    public static String certificationPeriod(CvResponse.CertificationDto certification) {
        String obtained = certification.getDateObtention() == null ? null
                : "Obtenue en " + certification.getDateObtention().format(DATE_FORMAT);
        String expires = certification.getDateExpiration() == null ? null
                : "Expiration : " + certification.getDateExpiration().format(DATE_FORMAT);
        return joinNonBlank("  •  ", obtained, expires);
    }

    public static String joinNonBlank(String separator, String... values) {
        StringBuilder result = new StringBuilder();
        for (String value : values) {
            if (value == null || value.isBlank()) continue;
            if (!result.isEmpty()) result.append(separator);
            result.append(value);
        }
        return result.isEmpty() ? null : result.toString();
    }

    public static void appendContact(Paragraph paragraph, String value, Font font) {
        if (value == null || value.isBlank()) return;
        if (!paragraph.isEmpty()) paragraph.add(new Chunk("   |   ", font));
        paragraph.add(new Chunk(value, font));
    }
}
