package com.cvmobile.service.notification;

/**
 * Contrat pour l'envoi de notifications push.
 * L'implementation utilise Firebase Cloud Messaging.
 * Si Firebase n'est pas configure, les appels sont ignores (graceful fallback).
 */
public interface INotificationService {

    void sendToUser(Long userId, String title, String body);

    void sendToToken(String fcmToken, String title, String body);

    boolean isConfigured();
}
