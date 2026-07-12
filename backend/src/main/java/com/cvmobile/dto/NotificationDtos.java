package com.cvmobile.dto;
import jakarta.validation.constraints.*;
public final class NotificationDtos {
    private NotificationDtos() {}
    public record DeviceTokenRequest(@NotBlank String token,
        @NotBlank @Pattern(regexp = "android|ios") String platform) {}
    public record TokenDeleteRequest(@NotBlank String token) {}
    public record Preferences(boolean staleCvEnabled, boolean cvViewsEnabled, boolean aiTipsEnabled) {}
}
