package com.cvmobile.service.notification;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;

/// Tests unitaires de FirebaseConfig (issue #258) : les methodes @Bean sont
/// appelees comme de simples methodes Java, sans charger le contexte Spring
/// (la classe n'est de toute facon active que si
/// notifications.firebase.enabled=true).
///
/// FirebaseApp et GoogleCredentials exposent uniquement des methodes
/// statiques pour l'init/lookup : elles sont mockees via
/// Mockito.mockStatic (inline mock maker, actif par defaut depuis
/// Mockito 5 - cf. FirebasePushGatewayTest). FirebaseOptions#getCredentials()
/// est package-private dans le SDK et donc inaccessible depuis ce test :
/// on verifie la causalite comportementale (getApplicationDefault() appele
/// une seule fois, uniquement sur le chemin sans app existante) plutot que
/// d'inspecter l'objet FirebaseOptions par reflexion.
class FirebaseConfigTest {

    private final FirebaseConfig config = new FirebaseConfig();

    @Test
    void firebaseApp_aucuneAppExistante_initialiseAvecLesCredentialsParDefaut() throws Exception {
        FirebaseApp initializedApp = mock(FirebaseApp.class);
        GoogleCredentials credentials = mock(GoogleCredentials.class);

        try (MockedStatic<FirebaseApp> firebaseAppStatic = mockStatic(FirebaseApp.class);
             MockedStatic<GoogleCredentials> credentialsStatic = mockStatic(GoogleCredentials.class)) {
            firebaseAppStatic.when(FirebaseApp::getApps).thenReturn(List.of());
            firebaseAppStatic.when(() -> FirebaseApp.initializeApp(any(FirebaseOptions.class)))
                    .thenReturn(initializedApp);
            credentialsStatic.when(GoogleCredentials::getApplicationDefault).thenReturn(credentials);

            FirebaseApp result = config.firebaseApp();

            assertThat(result).isSameAs(initializedApp);
            credentialsStatic.verify(GoogleCredentials::getApplicationDefault);
            firebaseAppStatic.verify(() -> FirebaseApp.initializeApp(any(FirebaseOptions.class)));
            firebaseAppStatic.verify(FirebaseApp::getInstance, never());
        }
    }

    @Test
    void firebaseApp_appDejaExistante_reutiliseLInstanceSansReinitialiser() throws Exception {
        FirebaseApp existingApp = mock(FirebaseApp.class);

        try (MockedStatic<FirebaseApp> firebaseAppStatic = mockStatic(FirebaseApp.class);
             MockedStatic<GoogleCredentials> credentialsStatic = mockStatic(GoogleCredentials.class)) {
            firebaseAppStatic.when(FirebaseApp::getApps).thenReturn(List.of(existingApp));
            firebaseAppStatic.when(FirebaseApp::getInstance).thenReturn(existingApp);

            FirebaseApp result = config.firebaseApp();

            assertThat(result).isSameAs(existingApp);
            firebaseAppStatic.verify(FirebaseApp::getInstance);
            firebaseAppStatic.verify(() -> FirebaseApp.initializeApp(any(FirebaseOptions.class)), never());
            credentialsStatic.verify(GoogleCredentials::getApplicationDefault, never());
        }
    }

    @Test
    void firebaseMessaging_delegueAFirebaseMessagingGetInstance() {
        FirebaseApp app = mock(FirebaseApp.class);
        FirebaseMessaging messaging = mock(FirebaseMessaging.class);

        try (MockedStatic<FirebaseMessaging> messagingStatic = mockStatic(FirebaseMessaging.class)) {
            messagingStatic.when(() -> FirebaseMessaging.getInstance(app)).thenReturn(messaging);

            FirebaseMessaging result = config.firebaseMessaging(app);

            assertThat(result).isSameAs(messaging);
            messagingStatic.verify(() -> FirebaseMessaging.getInstance(app));
        }
    }
}
