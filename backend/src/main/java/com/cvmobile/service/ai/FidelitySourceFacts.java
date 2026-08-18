package com.cvmobile.service.ai;

import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Project;

import java.time.LocalDate;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class FidelitySourceFacts {

    private static final Pattern NUMBER = Pattern.compile("\\d+(?:[.,]\\d+)?%?");

    private FidelitySourceFacts() {
    }

    static Set<String> allowedNumbers(Cv cv) {
        return extractNumbers(sourceText(cv));
    }

    static Set<String> extractNumbers(String text) {
        Set<String> numbers = new LinkedHashSet<>();
        if (text == null || text.isBlank()) {
            return numbers;
        }
        Matcher matcher = NUMBER.matcher(text);
        while (matcher.find()) {
            String raw = matcher.group();
            numbers.add(raw);
            numbers.add(raw.replace("%", ""));
            numbers.add(raw.replace(",", "."));
        }
        return numbers;
    }

    private static String sourceText(Cv cv) {
        StringBuilder dump = new StringBuilder();
        if (cv.getPersonalInfo() != null) {
            append(dump, cv.getPersonalInfo().getTitrePoste());
            append(dump, cv.getPersonalInfo().getResumeProfessionnel());
        }
        if (cv.getExperiences() != null) {
            for (Experience experience : cv.getExperiences()) {
                append(dump, experience.getPoste());
                append(dump, experience.getEntreprise());
                append(dump, experience.getLieu());
                append(dump, experience.getDescription());
                appendYear(dump, experience.getDateDebut());
                appendYear(dump, experience.getDateFin());
            }
        }
        if (cv.getEducations() != null) {
            for (Education education : cv.getEducations()) {
                append(dump, education.getEtablissement());
                append(dump, education.getDiplome());
                append(dump, education.getDomaine());
                append(dump, education.getDescription());
                appendYear(dump, education.getDateDebut());
                appendYear(dump, education.getDateFin());
            }
        }
        if (cv.getSkills() != null) {
            cv.getSkills().forEach(skill -> append(dump, skill.getNom()));
        }
        if (cv.getProjects() != null) {
            for (Project project : cv.getProjects()) {
                append(dump, project.getNom());
                append(dump, project.getDescription());
                append(dump, project.getTechnologies());
            }
        }
        if (cv.getCertifications() != null) {
            cv.getCertifications().forEach(certification -> {
                append(dump, certification.getNom());
                append(dump, certification.getOrganisme());
            });
        }
        return dump.toString();
    }

    private static void append(StringBuilder dump, String value) {
        if (value != null && !value.isBlank()) {
            dump.append(' ').append(value);
        }
    }

    private static void appendYear(StringBuilder dump, LocalDate date) {
        if (date != null) {
            dump.append(' ').append(date.getYear());
        }
    }
}
