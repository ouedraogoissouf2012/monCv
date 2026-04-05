package com.cvmobile.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "cvs")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Cv {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String titre;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Embedded
    private PersonalInfo personalInfo;

    @OneToMany(mappedBy = "cv", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    @OrderBy("dateDebut DESC")
    @org.hibernate.annotations.BatchSize(size = 20)
    private List<Education> educations = new ArrayList<>();

    @OneToMany(mappedBy = "cv", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    @OrderBy("dateDebut DESC")
    @org.hibernate.annotations.BatchSize(size = 20)
    private List<Experience> experiences = new ArrayList<>();

    @OneToMany(mappedBy = "cv", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    @org.hibernate.annotations.BatchSize(size = 20)
    private List<Skill> skills = new ArrayList<>();

    @OneToMany(mappedBy = "cv", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    @org.hibernate.annotations.BatchSize(size = 20)
    private List<Language> languages = new ArrayList<>();

    @OneToMany(mappedBy = "cv", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    @org.hibernate.annotations.BatchSize(size = 20)
    private List<Certification> certifications = new ArrayList<>();

    @OneToMany(mappedBy = "cv", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    @org.hibernate.annotations.BatchSize(size = 20)
    private List<Project> projects = new ArrayList<>();

    @Column(name = "public_token", unique = true)
    private String publicToken;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public void addEducation(Education education) {
        educations.add(education);
        education.setCv(this);
    }

    public void removeEducation(Education education) {
        educations.remove(education);
        education.setCv(null);
    }

    public void addExperience(Experience experience) {
        experiences.add(experience);
        experience.setCv(this);
    }

    public void removeExperience(Experience experience) {
        experiences.remove(experience);
        experience.setCv(null);
    }

    public void addSkill(Skill skill) {
        skills.add(skill);
        skill.setCv(this);
    }

    public void removeSkill(Skill skill) {
        skills.remove(skill);
        skill.setCv(null);
    }

    public void addLanguage(Language language) {
        languages.add(language);
        language.setCv(this);
    }

    public void removeLanguage(Language language) {
        languages.remove(language);
        language.setCv(null);
    }

    public void addCertification(Certification certification) {
        certifications.add(certification);
        certification.setCv(this);
    }

    public void removeCertification(Certification certification) {
        certifications.remove(certification);
        certification.setCv(null);
    }

    public void addProject(Project project) {
        projects.add(project);
        project.setCv(this);
    }

    public void removeProject(Project project) {
        projects.remove(project);
        project.setCv(null);
    }
}
