package com.cvmobile.service.notification;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.*;
import com.google.firebase.messaging.FirebaseMessaging;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.*;
import java.io.IOException;
@Configuration
@ConditionalOnProperty(name = "notifications.firebase.enabled", havingValue = "true")
public class FirebaseConfig {
    @Bean FirebaseApp firebaseApp() throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) return FirebaseApp.getInstance();
        return FirebaseApp.initializeApp(FirebaseOptions.builder()
            .setCredentials(GoogleCredentials.getApplicationDefault()).build());
    }
    @Bean FirebaseMessaging firebaseMessaging(FirebaseApp app) {
        return FirebaseMessaging.getInstance(app);
    }
}
