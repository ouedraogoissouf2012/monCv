package com.cvmobile.service.notification;

import com.cvmobile.config.NotificationProperties;
import com.cvmobile.dto.NotificationDtos;
import com.cvmobile.model.*;
import com.cvmobile.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;

@Slf4j
@Service @RequiredArgsConstructor
public class NotificationService {
    /** Taille de page des crons de rappels : borne la memoire et la duree de
     * chaque lecture, sans jamais retenir une transaction pendant les envois FCM. */
    private static final int REMINDER_PAGE_SIZE = 100;

    private final DeviceTokenRepository tokens;
    private final NotificationPreferenceRepository preferences;
    private final NotificationDeliveryRepository deliveries;
    private final CvRepository cvs;
    private final JobApplicationRepository applications;
    private final PushGateway gateway;
    private final NotificationProperties notificationProperties;

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

    // Crons de rappels : VOLONTAIREMENT hors @Transactional (M-5). Les envois FCM
    // sont des appels HTTP externes ; les tenir dans une transaction retiendrait
    // une connexion DB pendant tout le batch. Chaque lecture (requete paginee
    // fetch-join) et chaque enregistrement de dedup portent leur propre
    // transaction courte ; l'envoi se fait entre les deux, hors transaction.

    @Scheduled(cron = "${notifications.reminder-cron:0 0 9 * * *}")
    public void sendStaleCvReminders() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(notificationProperties.staleCvDays());
        String period = YearMonth.now().toString();
        for (int page = 0; ; page++) {
            List<Cv> batch = cvs.findStaleWithUser(cutoff, PageRequest.of(page, REMINDER_PAGE_SIZE));
            if (batch.isEmpty()) break;
            Map<Long, Boolean> staleEnabled = staleEnabledByUser(batch);
            for (Cv cv : batch) {
                if (!staleEnabled.getOrDefault(cv.getUser().getId(), true)) continue;
                dispatchQuietly(() -> sendOnce(cv, "STALE_CV", "stale:" + cv.getId() + ":" + period,
                    "Votre CV merite une mise a jour",
                    "Ajoutez vos nouvelles experiences et competences."));
            }
            if (batch.size() < REMINDER_PAGE_SIZE) break;
        }
    }

    @Scheduled(cron = "${notifications.application-reminder-cron:0 15 9 * * *}")
    public void sendApplicationFollowUpReminders() {
        List<JobApplicationStatus> terminalStatuses = List.of(
            JobApplicationStatus.OFFER,
            JobApplicationStatus.REJECTED,
            JobApplicationStatus.ARCHIVED);
        LocalDate today = LocalDate.now();
        for (int page = 0; ; page++) {
            List<JobApplication> batch = applications.findDueForFollowUpWithDetails(
                today, terminalStatuses, PageRequest.of(page, REMINDER_PAGE_SIZE));
            if (batch.isEmpty()) break;
            for (JobApplication application : batch) {
                String key = "application-follow-up:" + application.getId() + ":" + application.getNextFollowUp();
                dispatchQuietly(() -> sendOnce(application.getUser(), application.getCv(),
                    "APPLICATION_FOLLOW_UP", key,
                    "Relance de candidature",
                    "Pensez a relancer " + application.getCompany() + " pour le poste " + application.getPosition(),
                    "/applications"));
            }
            if (batch.size() < REMINDER_PAGE_SIZE) break;
        }
    }

    /** Preferences "CV inactif" du lot, chargees en une requete (evite le N+1) ;
     * absence de ligne = active par defaut (gere par le getOrDefault appelant). */
    private Map<Long, Boolean> staleEnabledByUser(List<Cv> batch) {
        List<Long> userIds = batch.stream().map(cv -> cv.getUser().getId()).distinct().toList();
        Map<Long, Boolean> enabled = new HashMap<>();
        for (NotificationPreference p : preferences.findAllById(userIds)) {
            enabled.put(p.getUserId(), p.isStaleCvEnabled());
        }
        return enabled;
    }

    /** Isole les erreurs par item : un envoi qui echoue (token invalide, dedup
     * concurrent, panne FCM) ne doit pas interrompre le reste du batch. */
    private void dispatchQuietly(Runnable send) {
        try {
            send.run();
        } catch (RuntimeException e) {
            log.warn("Rappel notification ignore apres erreur ({})", e.getClass().getSimpleName());
        }
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
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
        sendOnce(cv.getUser(), cv, type, key, title, body, "/cvs/" + cv.getId());
    }

    private void sendOnce(User user, Cv cv, String type, String key, String title, String body, String route) {
        if (deliveries.existsByDeduplicationKey(key)) return;
        boolean sent = false;
        Map<String, String> data = cv == null
            ? Map.of("type", type, "route", route)
            : Map.of("type", type, "cvId", cv.getId().toString(), "route", route);
        for (DeviceToken token : tokens.findByUserId(user.getId())) {
            sent |= gateway.send(token.getToken(), title, body, data);
        }
        if (!sent) return;
        try {
            deliveries.save(NotificationDelivery.builder().user(user).cv(cv)
                .notificationType(type).deduplicationKey(key).build());
        } catch (DataIntegrityViolationException ignored) {
            log.debug("Notification deja enregistree pour {}", key);
        }
    }

    private NotificationDtos.Preferences toDto(NotificationPreference p) {
        return new NotificationDtos.Preferences(p.isStaleCvEnabled(), p.isCvViewsEnabled(), p.isAiTipsEnabled());
    }
}
