package com.cvmobile.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Enregistrement d'une vue sur un CV partage publiquement.
 * Stocke un hash de l'IP (pas l'IP en clair) pour le deduplication.
 */
@Entity
@Table(name = "cv_views")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CvView {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cv_id", nullable = false)
    private Long cvId;

    @Column(name = "ip_hash", nullable = false, length = 16)
    private String ipHash;

    @Column(name = "viewed_at", nullable = false)
    private LocalDateTime viewedAt;

    @PrePersist
    protected void onCreate() {
        if (viewedAt == null) viewedAt = LocalDateTime.now();
    }
}
