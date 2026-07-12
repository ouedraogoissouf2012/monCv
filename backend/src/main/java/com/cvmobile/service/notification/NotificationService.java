package com.cvmobile.service.notification;

import com.cvmobile.dto.NotificationDtos;
import com.cvmobile.model.*;
import com.cvmobile.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.Map;

@Service @RequiredArgsConstructor
public class NotificationService {
    private final DeviceTokenRepository tokens;
    private final NotificationPreferenceRepository preferences;
    private final NotificationDeliveryRepository deliveries;
    private final CvRepository cvs;
    private final PushGateway gateway;

    @Value("${notifications.stale-cv-days:30}") private int staleCvDays;

    @Transactional
    public void registerDevice(User user, NotificationDtos.DeviceTokenRequest request) {
        DeviceToken device = tokens.findByToken(request.token()).orElseGet(DeviceToken::new);
        device.setUser(user);
        device.setToken(request.token());
        device.setPlatform(request.platform());
        tokens.save(device);
    }

    @Transactional
    public void unregisterDevice(User user, String token) {
        tokens.deleteByTokenAndUserId(token, user.getId());
    }

    @Transactional(readOnly = true)
    public NotificationDtos.Preferences getPreferences(User user) {
        return preferences.findById(user.getId()).map(this::toDto)
            .orElse(new NotificationDtos.Preferences(true, true, true));
    }

    @Transactional
    public NotificationDtos.Preferences updatePreferences(User user, NotificationDtos.Preferences dto) {
        NotificationPreference value = preferences.findById(user.getId())
            .orElseGet(() -> NotificationPreference.builder().user(user).build());
        value.setStaleCvEnabled(dto.staleCvEnabled());
        value.setCvViewsEnabled(dto.cvViewsEnabled());
        value.setAiTipsEnabled(dto.aiTipsEnabled());
        return toDto(preferences.save(value));
    }

    @Scheduled(cron = "${notifications.reminder-cron:0 0 9 * * *}")
    @Transactional
    public void sendStaleCvReminders() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(staleCvDays);
        for (Cv cv : cvs.findByUpdatedAtBefore(cutoff)) {
            if (!getPreferences(cv.getUser()).staleCvEnabled()) continue;
            String period = YearMonth.now().toString();
            sendOnce(cv, "STALE_CV", "stale:" + cv.getId() + ":" + period,
                "Votre CV merite une mise a jour",
                "Ajoutez vos nouvelles experiences et competences.");
        }
    }

    @Transactional
    public void notifyViewMilestone(Cv cv) {
        if (cv.getViewCount() < 10 || cv.getViewCount() % 10 != 0) return;
        if (!getPreferences(cv.getUser()).cvViewsEnabled()) return;
        sendOnce(cv, "CV_VIEWS", "views:" + cv.getId() + ":" + cv.getViewCount(),
            "Votre CV attire l'attention",
            "Il a maintenant " + cv.getViewCount() + " vues.");
    }

    @Transactional
    public void notifyAiTips(Cv cv, int improvementCount) {
        if (improvementCount <= 0 || !getPreferences(cv.getUser()).aiTipsEnabled()) return;
        String key = "ai:" + cv.getId() + ":" + cv.getUpdatedAt();
        sendOnce(cv, "AI_TIPS", key, "Votre CV peut encore progresser",
            improvementCount + " ameliorations personnalisees sont disponibles.");
    }

    private void sendOnce(Cv cv, String type, String key, String title, String body) {
        if (deliveries.existsByDeduplicationKey(key)) return;
        boolean sent = false;
        Map<String, String> data = Map.of("type", type, "cvId", cv.getId().toString(),
            "route", "/cvs/" + cv.getId());
        for (DeviceToken token : tokens.findByUserId(cv.getUser().getId())) {
            sent |= gateway.send(token.getToken(), title, body, data);
        }
        if (sent) deliveries.save(NotificationDelivery.builder().user(cv.getUser()).cv(cv)
            .notificationType(type).deduplicationKey(key).build());
    }

    private NotificationDtos.Preferences toDto(NotificationPreference p) {
        return new NotificationDtos.Preferences(p.isStaleCvEnabled(), p.isCvViewsEnabled(), p.isAiTipsEnabled());
    }
}
