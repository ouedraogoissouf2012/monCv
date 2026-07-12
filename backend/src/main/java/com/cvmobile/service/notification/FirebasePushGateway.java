package com.cvmobile.service.notification;
import com.google.firebase.messaging.*;
import lombok.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import java.util.Map;
@Slf4j @Component @RequiredArgsConstructor
@ConditionalOnProperty(name = "notifications.firebase.enabled", havingValue = "true")
public class FirebasePushGateway implements PushGateway {
    private final FirebaseMessaging messaging;
    public boolean send(String token, String title, String body, Map<String, String> data) {
        try {
            messaging.send(Message.builder().setToken(token)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .putAllData(data).build());
            return true;
        } catch (FirebaseMessagingException e) {
            log.warn("Echec FCM pour un appareil: {}", e.getMessagingErrorCode());
            return false;
        }
    }
}
