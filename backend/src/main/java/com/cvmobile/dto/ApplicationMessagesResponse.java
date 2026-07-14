package com.cvmobile.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ApplicationMessagesResponse {
    private String coverLetter;
    private String email;
    private String linkedIn;
    private String whatsApp;
    private String tone;
    private boolean aiGenerated;
    private boolean fallback;
}
