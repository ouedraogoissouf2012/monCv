package com.cvmobile.service.notification;

import com.cvmobile.model.DeviceToken;
import com.cvmobile.repository.DeviceTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Implementation du service de notifications.
 * Actuellement en mode "log only" — envoie les notifications aux logs.
 * Quand Firebase sera configure, remplacer les logs par des appels FCM.
 *
 * Pour activer Firebase :
 * 1. Ajouter firebase-admin dans pom.xml
 * 2. Configurer firebase.credentials-path dans application.yml
 * 3. Initialiser FirebaseApp au demarrage
 * 4. Remplacer les log.info par FirebaseMessaging.getInstance().send()
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements INotificationService {

    private final DeviceTokenRepository deviceTokenRepository;

    @Value("${firebase.enabled:false}")
    private boolean firebaseEnabled;

    @Override
    public boolean isConfigured() {
        return firebaseEnabled;
    }

    @Override
    public void sendToUser(Long userId, String title, String body) {
        List<DeviceToken> tokens = deviceTokenRepository.findByUserId(userId);
        if (tokens.isEmpty()) {
            log.debug("Aucun device token pour userId={}, notification ignoree", userId);
            return;
        }

        for (DeviceToken dt : tokens) {
            sendToToken(dt.getToken(), title, body);
        }
    }

    @Override
    public void sendToToken(String fcmToken, String title, String body) {
        if (!firebaseEnabled) {
            log.info("[NOTIFICATION PREVIEW] token={} | titre='{}' | body='{}'",
                    fcmToken.substring(0, Math.min(20, fcmToken.length())) + "...", title, body);
            return;
        }

        // TODO: Quand Firebase est configure, remplacer par :
        // Message message = Message.builder()
        //     .setToken(fcmToken)
        //     .setNotification(Notification.builder().setTitle(title).setBody(body).build())
        //     .build();
        // FirebaseMessaging.getInstance().send(message);
        log.info("Notification envoyee: token={}..., titre='{}'", fcmToken.substring(0, 20), title);
    }
}
