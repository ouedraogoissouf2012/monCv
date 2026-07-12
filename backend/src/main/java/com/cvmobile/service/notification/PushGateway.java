package com.cvmobile.service.notification;
import java.util.Map;
public interface PushGateway {
    boolean send(String token, String title, String body, Map<String, String> data);
}
