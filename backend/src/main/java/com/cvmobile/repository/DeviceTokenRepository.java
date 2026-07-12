package com.cvmobile.repository;
import com.cvmobile.model.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.*;
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    Optional<DeviceToken> findByToken(String token);
    List<DeviceToken> findByUserId(Long userId);
    void deleteByTokenAndUserId(String token, Long userId);
}
