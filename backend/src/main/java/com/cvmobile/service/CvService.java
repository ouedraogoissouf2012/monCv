package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
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

        cv = cvRepository.save(cv);
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
}
