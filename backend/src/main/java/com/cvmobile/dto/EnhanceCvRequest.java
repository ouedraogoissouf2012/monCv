package com.cvmobile.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class EnhanceCvRequest {

    @NotNull(message = "L'identifiant du CV est obligatoire")
    private Long cvId;

    @NotNull(message = "Le niveau d'amelioration est obligatoire")
    @Pattern(regexp = "LITE|MEDIUM|MAX", message = "Le niveau doit etre LITE, MEDIUM ou MAX")
    private String level;
}
