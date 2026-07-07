package com.cvmobile.scheduler;

import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.notification.INotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Planificateur de rappels pour les CVs non mis a jour.
 * Execute chaque lundi a 9h.
 * Envoie une notification push aux utilisateurs dont le CV
 * n'a pas ete modifie depuis plus de 30 jours.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CvReminderScheduler {

    private final CvRepository cvRepository;
    private final INotificationService notificationService;

    private static final int STALE_DAYS = 30;

    /**
     * Chaque lundi a 9h, verifie les CVs stales et envoie un rappel.
     */
    @Scheduled(cron = "0 0 9 * * MON")
    public void checkStaleCvs() {
        LocalDateTime threshold = LocalDateTime.now().minusDays(STALE_DAYS);
        List<Cv> staleCvs = cvRepository.findStaleCvs(threshold);

        // Grouper par userId les CVs non mis a jour depuis 30+ jours
        var staleByUser = staleCvs.stream()
                .filter(cv -> cv.getUser() != null)
                .collect(Collectors.groupingBy(cv -> cv.getUser().getId()));

        int notified = 0;
        for (var entry : staleByUser.entrySet()) {
            Long userId = entry.getKey();
            List<Cv> staleCvsList = entry.getValue();
            if (staleCvsList.isEmpty()) continue;
            long daysStale = ChronoUnit.DAYS.between(staleCvsList.get(0).getUpdatedAt(), LocalDateTime.now());

            notificationService.sendToUser(userId,
                    "Mettez a jour votre CV",
                    "Votre CV n'a pas ete modifie depuis " + daysStale + " jours. "
                    + "Un CV a jour augmente vos chances de 40%.");
            notified++;
        }

        log.info("Rappel CV: {} utilisateurs notifies ({} CVs stales, seuil={} jours)",
                notified, staleCvs.size(), STALE_DAYS);
    }
}
