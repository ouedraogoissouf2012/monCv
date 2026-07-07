package com.cvmobile.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "projects")
@Getter
@Setter
@ToString(exclude = {"cv"})
@EqualsAndHashCode(of = {"id"})
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nom;

    @Column(length = 1000)
    private String description;

    @Column(length = 500)
    private String technologies;

    @Column(length = 500)
    private String lien;

    private LocalDate dateDebut;

    private LocalDate dateFin;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cv_id")
    @JsonIgnore
    private Cv cv;
}
