package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Certification;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.Education;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.cv.domain.model.Language;
import com.cvmobile.cv.domain.model.Project;
import com.cvmobile.cv.domain.model.Skill;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Duplique un CV possede en une copie independante (issue #255).
 *
 * <p>La copie est un CV neuf (sans identifiant) intitule « Copie de … »,
 * reprenant style, informations personnelles et sections. Chaque section est
 * recreee <strong>sans</strong> identifiant, afin d'etre persistee comme un
 * nouvel enregistrement plutot que de deplacer l'original.
 */
@Service
public class DuplicateCvUseCase {

    private final CvRepositoryPort repository;

    public DuplicateCvUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    /**
     * @throws CvNotFoundException si aucun CV possede ne correspond
     */
    @Transactional
    public Cv duplicate(long cvId, long ownerId) {
        Cv original = repository.findByIdAndOwnerId(cvId, ownerId)
                .orElseThrow(() -> new CvNotFoundException(cvId));

        Cv copy = Cv.create("Copie de " + original.getTitre(), ownerId);
        copy.changeStyle(original.getStyle());
        copy.changePersonalInfo(original.getPersonalInfo());

        original.getExperiences().forEach(e -> copy.addExperience(copyOf(e)));
        original.getEducations().forEach(e -> copy.addEducation(copyOf(e)));
        original.getSkills().forEach(s -> copy.addSkill(copyOf(s)));
        original.getLanguages().forEach(l -> copy.addLanguage(copyOf(l)));
        original.getCertifications().forEach(c -> copy.addCertification(copyOf(c)));
        original.getProjects().forEach(p -> copy.addProject(copyOf(p)));

        return repository.save(copy);
    }

    private static Experience copyOf(Experience e) {
        return Experience.of(null, e.entreprise(), e.poste(), e.lieu(),
                e.dateDebut(), e.dateFin(), e.description(), e.actuel());
    }

    private static Education copyOf(Education e) {
        return Education.of(null, e.etablissement(), e.diplome(), e.domaine(),
                e.dateDebut(), e.dateFin(), e.description());
    }

    private static Skill copyOf(Skill s) {
        return Skill.of(null, s.nom(), s.niveau(), s.categorie());
    }

    private static Language copyOf(Language l) {
        return Language.of(null, l.langue(), l.niveau());
    }

    private static Certification copyOf(Certification c) {
        return Certification.of(null, c.nom(), c.organisme(),
                c.dateObtention(), c.dateExpiration(), c.credentialUrl());
    }

    private static Project copyOf(Project p) {
        return Project.of(null, p.nom(), p.description(), p.technologies(),
                p.lien(), p.dateDebut(), p.dateFin());
    }
}
