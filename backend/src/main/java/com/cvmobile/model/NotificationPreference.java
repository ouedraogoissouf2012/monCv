package com.cvmobile.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notification_preferences")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class NotificationPreference {
    @Id
    @Column(name = "user_id")
    private Long userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Builder.Default private boolean staleCvEnabled = true;
    @Builder.Default private boolean cvViewsEnabled = true;
    @Builder.Default private boolean aiTipsEnabled = true;
    @Column(name = "updated_at") private LocalDateTime updatedAt;

    @PrePersist @PreUpdate
    void touch() { updatedAt = LocalDateTime.now(); }
}
