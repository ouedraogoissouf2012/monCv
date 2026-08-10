package com.cvmobile.service.notification;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/// Tests unitaires de FirebasePushGateway (issue #258) : delegation a
/// FirebaseMessaging et degradation gracieuse (jamais d'exception propagee au
/// gateway.send() en cas d'echec fournisseur).
///
/// Le contenu du Message construit (token/titre/corps/data) n'est PAS
/// inspectable ici : Message expose ses getters en package-private (SDK
/// Firebase), donc introuvables depuis un test hors de son package. Le
/// comportement observable teste est la delegation (un appel effectif a
/// messaging.send) et le mapping succes/echec vers le booleen de retour.
class FirebasePushGatewayTest {

    private final FirebaseMessaging messaging = mock(FirebaseMessaging.class);
    private final FirebasePushGateway gateway = new FirebasePushGateway(messaging);

    @Test
    void send_succes_delegueAFirebaseMessagingEtRetourneTrue() throws Exception {
        when(messaging.send(any(Message.class))).thenReturn("projects/x/messages/1");

        boolean sent = gateway.send(
                "device-token", "Titre", "Corps", Map.of("cle", "valeur"));

        assertThat(sent).isTrue();
        verify(messaging).send(any(Message.class));
    }

    @Test
    void send_echecFcm_retourneFalseSansPropagerLException() throws Exception {
        // Classe finale du SDK : mockable grace a l'inline mock maker (Mockito 5).
        FirebaseMessagingException failure = mock(FirebaseMessagingException.class);
        when(failure.getMessagingErrorCode()).thenReturn(MessagingErrorCode.UNREGISTERED);
        when(messaging.send(any(Message.class))).thenThrow(failure);

        boolean sent = gateway.send("token-invalide", "Titre", "Corps", Map.of());

        assertThat(sent).isFalse();
    }
}
