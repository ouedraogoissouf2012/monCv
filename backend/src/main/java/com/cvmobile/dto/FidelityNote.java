package com.cvmobile.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class FidelityNote {

    public static final String UNCHANGED = "UNCHANGED";
    public static final String REFORMULATED = "REFORMULATED";
    public static final String REFUSED = "REFUSED";

    private String field;
    private String status;
    private String reason;
}
