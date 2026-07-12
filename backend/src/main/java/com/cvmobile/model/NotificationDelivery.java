package com.cvmobile.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "notification_deliveries")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class NotificationDelivery {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private User user;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "cv_id") private Cv cv;
    @Column(name = "notification_type", nullable = false, length = 40) private String notificationType;
    @Column(name = "deduplication_key", nullable = false, unique = true, length = 160) private String deduplicationKey;
    @Column(name = "sent_at", nullable = false) private LocalDateTime sentAt;
    @PrePersist void create() { if (sentAt == null) sentAt = LocalDateTime.now(); }
}
