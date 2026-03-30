package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CvService {

    private final CvRepository cvRepository;
    private final UserService userService;

    public List<CvResponse> getAllCvsByUserId(Long userId) {
        return cvRepository.findByUserId(userId).stream()
                .map(CvResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public CvResponse getCvById(Long cvId, Long userId) {
        Cv cv = cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new RuntimeException("CV non trouve"));
        return CvResponse.fromEntity(cv);
    }

    public CvResponse getCvWithDetails(Long cvId) {
        Cv cv = cvRepository.findByIdWithDetails(cvId)
                .orElseThrow(() -> new RuntimeException("CV non trouve"));
        return CvResponse.fromEntity(cv);
    }

    @Transactional
    public CvResponse createCv(CvRequest request, Long userId) {
        User user = userService.findById(userId);

        Cv cv = Cv.builder()
                .titre(request.getTitre())
                .user(user)
                .build();

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(mapPersonalInfo(request.getPersonalInfo()));
        }

        cv = cvRepository.save(cv);

        if (request.getEducations() != null) {
            for (CvRequest.EducationDto eduDto : request.getEducations()) {
                Education education = mapEducation(eduDto);
                cv.addEducation(education);
            }
        }

        if (request.getExperiences() != null) {
            for (CvRequest.ExperienceDto expDto : request.getExperiences()) {
                Experience experience = mapExperience(expDto);
                cv.addExperience(experience);
            }
        }

        if (request.getSkills() != null) {
            for (CvRequest.SkillDto skillDto : request.getSkills()) {
                Skill skill = mapSkill(skillDto);
                cv.addSkill(skill);
            }
        }

        if (request.getLanguages() != null) {
            for (CvRequest.LanguageDto langDto : request.getLanguages()) {
                Language language = mapLanguage(langDto);
                cv.addLanguage(language);
            }
        }

        if (request.getCertifications() != null) {
            for (CvRequest.CertificationDto certDto : request.getCertifications()) {
                cv.addCertification(mapCertification(certDto));
            }
        }

        if (request.getProjects() != null) {
            for (CvRequest.ProjectDto projDto : request.getProjects()) {
                cv.addProject(mapProject(projDto));
            }
        }

        cv = cvRepository.save(cv);
        return CvResponse.fromEntity(cv);
    }

    @Transactional
    public CvResponse updateCv(Long cvId, CvRequest request, Long userId) {
        Cv cv = cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new RuntimeException("CV non trouve"));

        cv.setTitre(request.getTitre());

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(mapPersonalInfo(request.getPersonalInfo()));
        }

        // Clear and rebuild collections
        cv.getEducations().clear();
        if (request.getEducations() != null) {
            for (CvRequest.EducationDto eduDto : request.getEducations()) {
                Education education = mapEducation(eduDto);
                cv.addEducation(education);
            }
        }

        cv.getExperiences().clear();
        if (request.getExperiences() != null) {
            for (CvRequest.ExperienceDto expDto : request.getExperiences()) {
                Experience experience = mapExperience(expDto);
                cv.addExperience(experience);
            }
        }

        cv.getSkills().clear();
        if (request.getSkills() != null) {
            for (CvRequest.SkillDto skillDto : request.getSkills()) {
                Skill skill = mapSkill(skillDto);
                cv.addSkill(skill);
            }
        }

        cv.getLanguages().clear();
        if (request.getLanguages() != null) {
            for (CvRequest.LanguageDto langDto : request.getLanguages()) {
                Language language = mapLanguage(langDto);
                cv.addLanguage(language);
            }
        }

        cv.getCertifications().clear();
        if (request.getCertifications() != null) {
            for (CvRequest.CertificationDto certDto : request.getCertifications()) {
                cv.addCertification(mapCertification(certDto));
            }
        }

        cv.getProjects().clear();
        if (request.getProjects() != null) {
            for (CvRequest.ProjectDto projDto : request.getProjects()) {
                cv.addProject(mapProject(projDto));
            }
        }

        cv = cvRepository.save(cv);
        return CvResponse.fromEntity(cv);
    }

    @Transactional
    public CvResponse duplicateCv(Long cvId, Long userId) {
        Cv original = cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new RuntimeException("CV non trouve"));
        User user = userService.findById(userId);

        Cv copy = Cv.builder()
                .titre("Copie de " + original.getTitre())
                .user(user)
                .build();

        if (original.getPersonalInfo() != null) {
            PersonalInfo pi = original.getPersonalInfo();
            copy.setPersonalInfo(PersonalInfo.builder()
                    .nom(pi.getNom()).prenom(pi.getPrenom()).email(pi.getEmail())
                    .telephone(pi.getTelephone()).adresse(pi.getAdresse())
                    .ville(pi.getVille()).codePostal(pi.getCodePostal()).pays(pi.getPays())
                    .photoUrl(pi.getPhotoUrl()).linkedIn(pi.getLinkedIn())
                    .portfolio(pi.getPortfolio()).titrePoste(pi.getTitrePoste())
                    .resumeProfessionnel(pi.getResumeProfessionnel())
                    .build());
        }

        copy = cvRepository.save(copy);

        for (Education e : original.getEducations()) {
            copy.addEducation(Education.builder()
                    .etablissement(e.getEtablissement()).diplome(e.getDiplome())
                    .domaine(e.getDomaine()).dateDebut(e.getDateDebut())
                    .dateFin(e.getDateFin()).description(e.getDescription())
                    .build());
        }
        for (Experience e : original.getExperiences()) {
            copy.addExperience(Experience.builder()
                    .entreprise(e.getEntreprise()).poste(e.getPoste())
                    .lieu(e.getLieu()).dateDebut(e.getDateDebut())
                    .dateFin(e.getDateFin()).description(e.getDescription())
                    .actuel(e.getActuel())
                    .build());
        }
        for (Skill s : original.getSkills()) {
            copy.addSkill(Skill.builder()
                    .nom(s.getNom()).niveau(s.getNiveau()).categorie(s.getCategorie())
                    .build());
        }
        for (Language l : original.getLanguages()) {
            copy.addLanguage(Language.builder()
                    .langue(l.getLangue()).niveau(l.getNiveau())
                    .build());
        }
        for (Certification c : original.getCertifications()) {
            copy.addCertification(Certification.builder()
                    .nom(c.getNom()).organisme(c.getOrganisme())
                    .dateObtention(c.getDateObtention())
                    .dateExpiration(c.getDateExpiration())
                    .credentialUrl(c.getCredentialUrl())
                    .build());
        }
        for (Project p : original.getProjects()) {
            copy.addProject(Project.builder()
                    .nom(p.getNom()).description(p.getDescription())
                    .technologies(p.getTechnologies()).lien(p.getLien())
                    .dateDebut(p.getDateDebut()).dateFin(p.getDateFin())
                    .build());
        }

        copy = cvRepository.save(copy);
        return CvResponse.fromEntity(copy);
    }

    @Transactional
    public CvResponse generateShareToken(Long cvId, Long userId) {
        Cv cv = cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new RuntimeException("CV non trouve"));
        if (cv.getPublicToken() == null) {
            cv.setPublicToken(UUID.randomUUID().toString().replace("-", ""));
            cv = cvRepository.save(cv);
        }
        return CvResponse.fromEntity(cv);
    }

    public CvResponse getCvByPublicToken(String token) {
        Cv cv = cvRepository.findByPublicToken(token)
                .orElseThrow(() -> new RuntimeException("Lien invalide ou expiré"));
        return CvResponse.fromEntity(cv);
    }

    @Transactional
    public void deleteCv(Long cvId, Long userId) {
        if (!cvRepository.existsByIdAndUserId(cvId, userId)) {
            throw new RuntimeException("CV non trouve");
        }
        cvRepository.deleteById(cvId);
    }

    private PersonalInfo mapPersonalInfo(CvRequest.PersonalInfoDto dto) {
        return PersonalInfo.builder()
                .nom(dto.getNom())
                .prenom(dto.getPrenom())
                .email(dto.getEmail())
                .telephone(dto.getTelephone())
                .adresse(dto.getAdresse())
                .ville(dto.getVille())
                .codePostal(dto.getCodePostal())
                .pays(dto.getPays())
                .photoUrl(dto.getPhotoUrl())
                .linkedIn(dto.getLinkedIn())
                .portfolio(dto.getPortfolio())
                .titrePoste(dto.getTitrePoste())
                .resumeProfessionnel(dto.getResumeProfessionnel())
                .build();
    }

    private Education mapEducation(CvRequest.EducationDto dto) {
        return Education.builder()
                .etablissement(dto.getEtablissement())
                .diplome(dto.getDiplome())
                .domaine(dto.getDomaine())
                .dateDebut(dto.getDateDebut())
                .dateFin(dto.getDateFin())
                .description(dto.getDescription())
                .build();
    }

    private Experience mapExperience(CvRequest.ExperienceDto dto) {
        return Experience.builder()
                .entreprise(dto.getEntreprise())
                .poste(dto.getPoste())
                .lieu(dto.getLieu())
                .dateDebut(dto.getDateDebut())
                .dateFin(dto.getDateFin())
                .description(dto.getDescription())
                .actuel(dto.getActuel() != null ? dto.getActuel() : false)
                .build();
    }

    private Skill mapSkill(CvRequest.SkillDto dto) {
        return Skill.builder()
                .nom(dto.getNom())
                .niveau(dto.getNiveau())
                .categorie(dto.getCategorie())
                .build();
    }

    private Language mapLanguage(CvRequest.LanguageDto dto) {
        return Language.builder()
                .langue(dto.getLangue())
                .niveau(dto.getNiveau())
                .build();
    }

    private Certification mapCertification(CvRequest.CertificationDto dto) {
        return Certification.builder()
                .nom(dto.getNom())
                .organisme(dto.getOrganisme())
                .dateObtention(dto.getDateObtention())
                .dateExpiration(dto.getDateExpiration())
                .credentialUrl(dto.getCredentialUrl())
                .build();
    }

    private Project mapProject(CvRequest.ProjectDto dto) {
        return Project.builder()
                .nom(dto.getNom())
                .description(dto.getDescription())
                .technologies(dto.getTechnologies())
                .lien(dto.getLien())
                .dateDebut(dto.getDateDebut())
                .dateFin(dto.getDateFin())
                .build();
    }
}
