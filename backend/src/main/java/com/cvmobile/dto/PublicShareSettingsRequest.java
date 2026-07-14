package com.cvmobile.dto;

import lombok.Data;

@Data
public class PublicShareSettingsRequest {
    private boolean downloadsEnabled;
    private boolean contactEnabled;
}

