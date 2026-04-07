package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.cv.ICvService;
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CvService implements ICvService {

    private final CvRepository cvRepository;
    private final IUserService userService;

    // ── Lecture ───────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<CvResponse> getAllCvsByUserId(Long userId) {
        return cvRepository.findByUserIdWithDetails(userId).stream()
                .map(CvResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public CvResponse getCvById(Long cvId, Long userId) {
        Cv cv = findCvOrThrow(cvId, userId);
        return CvResponse.fromEntity(cv);
    }

    @Transactional(readOnly = true)
    public CvResponse getCvWithDetails(Long cvId) {
        Cv cv = cvRepository.findByIdWithDetails(cvId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
        return CvResponse.fromEntity(cv);
    }

    @Transactional(readOnly = true)
    public CvResponse getCvByPublicToken(String token) {
        Cv cv = cvRepository.findByPublicToken(token)
                .orElseThrow(() -> new ResourceNotFoundException("Lien de partage invalide ou expire"));
        return CvResponse.fromEntity(cv);
    }

    // ── Creation ─────────────────────────────────────────────────

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
        addNewCollections(cv, request);
        cv = cvRepository.save(cv);

        log.info("CV cree: id={}, titre='{}', userId={}", cv.getId(), cv.getTitre(), userId);
        return CvResponse.fromEntity(cv);
    }

    // ── Mise a jour ──────────────────────────────────────────────

    @Transactional
    public CvResponse updateCv(Long cvId, CvRequest request, Long userId) {
        Cv cv = findCvOrThrow(cvId, userId);

        cv.setTitre(request.getTitre());

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(mapPersonalInfo(request.getPersonalInfo()));
        }

        smartMergeCollections(cv, request);

        cv = cvRepository.save(cv);
        log.info("CV mis a jour: id={}, userId={}", cvId, userId);
        return CvResponse.fromEntity(cv);
    }

    // ── Duplication ──────────────────────────────────────────────

    @Transactional
    public CvResponse duplicateCv(Long cvId, Long userId) {
        Cv original = findCvOrThrow(cvId, userId);
        User user = userService.findById(userId);

        Cv copy = Cv.builder()
                .titre("Copie de " + original.getTitre())
                .user(user)
                .build();

        if (original.getPersonalInfo() != null) {
            copy.setPersonalInfo(copyPersonalInfo(original.getPersonalInfo()));
        }

        Cv savedCopy = cvRepository.save(copy);

        original.getEducations().forEach(e -> savedCopy.addEducation(copyEducation(e)));
        original.getExperiences().forEach(e -> savedCopy.addExperience(copyExperience(e)));
        original.getSkills().forEach(s -> savedCopy.addSkill(copySkill(s)));
        original.getLanguages().forEach(l -> savedCopy.addLanguage(copyLanguage(l)));
        original.getCertifications().forEach(c -> savedCopy.addCertification(copyCertification(c)));
        original.getProjects().forEach(p -> savedCopy.addProject(copyProject(p)));

        Cv saved = cvRepository.save(savedCopy);
        log.info("CV duplique: original={}, copie={}, userId={}", cvId, saved.getId(), userId);
        return CvResponse.fromEntity(saved);
    }

    // ── Partage ──────────────────────────────────────────────────

    @Transactional
    public CvResponse generateShareToken(Long cvId, Long userId) {
        Cv cv = findCvOrThrow(cvId, userId);
        if (cv.getPublicToken() == null) {
            cv.setPublicToken(UUID.randomUUID().toString().replace("-", ""));
            cv = cvRepository.save(cv);
            log.info("Token de partage genere pour CV id={}", cvId);
        }
        return CvResponse.fromEntity(cv);
    }

    // ── Suppression ──────────────────────────────────────────────

    @Transactional
    public void deleteCv(Long cvId, Long userId) {
        if (!cvRepository.existsByIdAndUserId(cvId, userId)) {
            throw new ResourceNotFoundException("CV", "id", cvId);
        }
        cvRepository.deleteById(cvId);
        log.info("CV supprime: id={}, userId={}", cvId, userId);
    }

    // ── Helpers prives ───────────────────────────────────────────

    private Cv findCvOrThrow(Long cvId, Long userId) {
        return cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
    }

    /** Ajout simple de collections (pour la creation uniquement). */
    private void addNewCollections(Cv cv, CvRequest request) {
        if (request.getExperiences() != null)
            request.getExperiences().forEach(d -> cv.addExperience(mapExperience(d)));
        if (request.getEducations() != null)
            request.getEducations().forEach(d -> cv.addEducation(mapEducation(d)));
        if (request.getSkills() != null)
            request.getSkills().forEach(d -> cv.addSkill(mapSkill(d)));
        if (request.getLanguages() != null)
            request.getLanguages().forEach(d -> cv.addLanguage(mapLanguage(d)));
        if (request.getCertifications() != null)
            request.getCertifications().forEach(d -> cv.addCertification(mapCertification(d)));
        if (request.getProjects() != null)
            request.getProjects().forEach(d -> cv.addProject(mapProject(d)));
    }

    /**
     * Smart merge : compare les collections existantes avec les nouvelles.
     * - Si l'element a un ID qui existe deja → update in place
     * - Si l'element n'a pas d'ID → insert (nouveau)
     * - Si un element existant n'est plus dans la requete → delete
     *
     * Avantage : les IDs restent stables entre les updates.
     */
    private void smartMergeCollections(Cv cv, CvRequest request) {
        mergeExperiences(cv, request.getExperiences());
        mergeEducations(cv, request.getEducations());
        mergeSkills(cv, request.getSkills());
        mergeLanguages(cv, request.getLanguages());
        mergeCertifications(cv, request.getCertifications());
        mergeProjects(cv, request.getProjects());
    }

    private void mergeExperiences(Cv cv, List<CvRequest.ExperienceDto> dtos) {
        if (dtos == null) { cv.getExperiences().clear(); return; }
        var existing = cv.getExperiences();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(java.util.stream.Collectors.toMap(Experience::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.ExperienceDto::getId)
                .filter(id -> id != null).collect(java.util.stream.Collectors.toSet());

        // Supprimer ceux qui ne sont plus dans la requete
        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                // Update existant
                var exp = existingById.get(dto.getId());
                exp.setPoste(dto.getPoste());
                exp.setEntreprise(dto.getEntreprise());
                exp.setLieu(dto.getLieu());
                exp.setDateDebut(dto.getDateDebut());
                exp.setDateFin(dto.getDateFin());
                exp.setDescription(dto.getDescription());
                exp.setActuel(dto.getActuel() != null ? dto.getActuel() : false);
            } else {
                // Nouveau
                cv.addExperience(mapExperience(dto));
            }
        }
    }

    private void mergeEducations(Cv cv, List<CvRequest.EducationDto> dtos) {
        if (dtos == null) { cv.getEducations().clear(); return; }
        var existing = cv.getEducations();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(java.util.stream.Collectors.toMap(Education::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.EducationDto::getId)
                .filter(id -> id != null).collect(java.util.stream.Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                var edu = existingById.get(dto.getId());
                edu.setEtablissement(dto.getEtablissement());
                edu.setDiplome(dto.getDiplome());
                edu.setDomaine(dto.getDomaine());
                edu.setDateDebut(dto.getDateDebut());
                edu.setDateFin(dto.getDateFin());
                edu.setDescription(dto.getDescription());
            } else {
                cv.addEducation(mapEducation(dto));
            }
        }
    }

    private void mergeSkills(Cv cv, List<CvRequest.SkillDto> dtos) {
        if (dtos == null) { cv.getSkills().clear(); return; }
        var existing = cv.getSkills();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(java.util.stream.Collectors.toMap(Skill::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.SkillDto::getId)
                .filter(id -> id != null).collect(java.util.stream.Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                var skill = existingById.get(dto.getId());
                skill.setNom(dto.getNom());
                skill.setNiveau(dto.getNiveau());
                skill.setCategorie(dto.getCategorie());
            } else {
                cv.addSkill(mapSkill(dto));
            }
        }
    }

    private void mergeLanguages(Cv cv, List<CvRequest.LanguageDto> dtos) {
        if (dtos == null) { cv.getLanguages().clear(); return; }
        var existing = cv.getLanguages();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(java.util.stream.Collectors.toMap(Language::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.LanguageDto::getId)
                .filter(id -> id != null).collect(java.util.stream.Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                var lang = existingById.get(dto.getId());
                lang.setLangue(dto.getLangue());
                lang.setNiveau(dto.getNiveau());
            } else {
                cv.addLanguage(mapLanguage(dto));
            }
        }
    }

    private void mergeCertifications(Cv cv, List<CvRequest.CertificationDto> dtos) {
        if (dtos == null) { cv.getCertifications().clear(); return; }
        var existing = cv.getCertifications();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(java.util.stream.Collectors.toMap(Certification::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.CertificationDto::getId)
                .filter(id -> id != null).collect(java.util.stream.Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                var cert = existingById.get(dto.getId());
                cert.setNom(dto.getNom());
                cert.setOrganisme(dto.getOrganisme());
                cert.setDateObtention(dto.getDateObtention());
                cert.setDateExpiration(dto.getDateExpiration());
                cert.setCredentialUrl(dto.getCredentialUrl());
            } else {
                cv.addCertification(mapCertification(dto));
            }
        }
    }

    private void mergeProjects(Cv cv, List<CvRequest.ProjectDto> dtos) {
        if (dtos == null) { cv.getProjects().clear(); return; }
        var existing = cv.getProjects();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(java.util.stream.Collectors.toMap(Project::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.ProjectDto::getId)
                .filter(id -> id != null).collect(java.util.stream.Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                var proj = existingById.get(dto.getId());
                proj.setNom(dto.getNom());
                proj.setDescription(dto.getDescription());
                proj.setTechnologies(dto.getTechnologies());
                proj.setLien(dto.getLien());
                proj.setDateDebut(dto.getDateDebut());
                proj.setDateFin(dto.getDateFin());
            } else {
                cv.addProject(mapProject(dto));
            }
        }
    }

    // ── Mappers DTO -> Entity ────────────────────────────────────

    private PersonalInfo mapPersonalInfo(CvRequest.PersonalInfoDto dto) {
        return PersonalInfo.builder()
                .nom(dto.getNom()).prenom(dto.getPrenom()).email(dto.getEmail())
                .telephone(dto.getTelephone()).adresse(dto.getAdresse())
                .ville(dto.getVille()).codePostal(dto.getCodePostal()).pays(dto.getPays())
                .photoUrl(dto.getPhotoUrl()).linkedIn(dto.getLinkedIn())
                .portfolio(dto.getPortfolio()).titrePoste(dto.getTitrePoste())
                .resumeProfessionnel(dto.getResumeProfessionnel())
                .build();
    }

    private Education mapEducation(CvRequest.EducationDto dto) {
        return Education.builder()
                .etablissement(dto.getEtablissement()).diplome(dto.getDiplome())
                .domaine(dto.getDomaine()).dateDebut(dto.getDateDebut())
                .dateFin(dto.getDateFin()).description(dto.getDescription())
                .build();
    }

    private Experience mapExperience(CvRequest.ExperienceDto dto) {
        return Experience.builder()
                .entreprise(dto.getEntreprise()).poste(dto.getPoste())
                .lieu(dto.getLieu()).dateDebut(dto.getDateDebut())
                .dateFin(dto.getDateFin()).description(dto.getDescription())
                .actuel(dto.getActuel() != null ? dto.getActuel() : false)
                .build();
    }

    private Skill mapSkill(CvRequest.SkillDto dto) {
        return Skill.builder().nom(dto.getNom()).niveau(dto.getNiveau()).categorie(dto.getCategorie()).build();
    }

    private Language mapLanguage(CvRequest.LanguageDto dto) {
        return Language.builder().langue(dto.getLangue()).niveau(dto.getNiveau()).build();
    }

    private Certification mapCertification(CvRequest.CertificationDto dto) {
        return Certification.builder()
                .nom(dto.getNom()).organisme(dto.getOrganisme())
                .dateObtention(dto.getDateObtention()).dateExpiration(dto.getDateExpiration())
                .credentialUrl(dto.getCredentialUrl())
                .build();
    }

    private Project mapProject(CvRequest.ProjectDto dto) {
        return Project.builder()
                .nom(dto.getNom()).description(dto.getDescription())
                .technologies(dto.getTechnologies()).lien(dto.getLien())
                .dateDebut(dto.getDateDebut()).dateFin(dto.getDateFin())
                .build();
    }

    // ── Copiers pour duplication ──────────────────────────────────

    private PersonalInfo copyPersonalInfo(PersonalInfo pi) {
        return PersonalInfo.builder()
                .nom(pi.getNom()).prenom(pi.getPrenom()).email(pi.getEmail())
                .telephone(pi.getTelephone()).adresse(pi.getAdresse())
                .ville(pi.getVille()).codePostal(pi.getCodePostal()).pays(pi.getPays())
                .photoUrl(pi.getPhotoUrl()).linkedIn(pi.getLinkedIn())
                .portfolio(pi.getPortfolio()).titrePoste(pi.getTitrePoste())
                .resumeProfessionnel(pi.getResumeProfessionnel())
                .build();
    }

    private Education copyEducation(Education e) {
        return Education.builder().etablissement(e.getEtablissement()).diplome(e.getDiplome())
                .domaine(e.getDomaine()).dateDebut(e.getDateDebut())
                .dateFin(e.getDateFin()).description(e.getDescription()).build();
    }

    private Experience copyExperience(Experience e) {
        return Experience.builder().entreprise(e.getEntreprise()).poste(e.getPoste())
                .lieu(e.getLieu()).dateDebut(e.getDateDebut()).dateFin(e.getDateFin())
                .description(e.getDescription()).actuel(e.getActuel()).build();
    }

    private Skill copySkill(Skill s) {
        return Skill.builder().nom(s.getNom()).niveau(s.getNiveau()).categorie(s.getCategorie()).build();
    }

    private Language copyLanguage(Language l) {
        return Language.builder().langue(l.getLangue()).niveau(l.getNiveau()).build();
    }

    private Certification copyCertification(Certification c) {
        return Certification.builder().nom(c.getNom()).organisme(c.getOrganisme())
                .dateObtention(c.getDateObtention()).dateExpiration(c.getDateExpiration())
                .credentialUrl(c.getCredentialUrl()).build();
    }

    private Project copyProject(Project p) {
        return Project.builder().nom(p.getNom()).description(p.getDescription())
                .technologies(p.getTechnologies()).lien(p.getLien())
                .dateDebut(p.getDateDebut()).dateFin(p.getDateFin()).build();
    }
}
