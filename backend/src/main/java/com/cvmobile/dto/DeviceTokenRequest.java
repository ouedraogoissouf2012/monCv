package com.cvmobile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class DeviceTokenRequest {

    @NotBlank(message = "Le token FCM est obligatoire")
    @Size(max = 500, message = "Le token ne doit pas depasser 500 caracteres")
    private String token;

    private String platform;
}
