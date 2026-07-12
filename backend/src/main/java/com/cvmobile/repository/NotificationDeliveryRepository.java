package com.cvmobile.repository;
import com.cvmobile.model.NotificationDelivery;
import org.springframework.data.jpa.repository.JpaRepository;
public interface NotificationDeliveryRepository extends JpaRepository<NotificationDelivery, Long> {
    boolean existsByDeduplicationKey(String key);
}
