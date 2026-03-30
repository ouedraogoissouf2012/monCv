package com.cvmobile.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class EnhanceCvRequest {

    @NotNull
    private Long cvId;

    /** LITE | MEDIUM | MAX */
    @NotNull
    private String level;
}
