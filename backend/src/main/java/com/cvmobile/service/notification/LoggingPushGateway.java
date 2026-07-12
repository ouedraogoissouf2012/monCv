package com.cvmobile.service.notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import java.util.Map;
@Slf4j @Component
@ConditionalOnProperty(name = "notifications.firebase.enabled", havingValue = "false", matchIfMissing = true)
public class LoggingPushGateway implements PushGateway {
    public boolean send(String token, String title, String body, Map<String, String> data) {
        log.info("Notification simulee: tokenSuffix={}, title={}, data={}",
            token.substring(Math.max(0, token.length() - 6)), title, data);
        return true;
    }
}
