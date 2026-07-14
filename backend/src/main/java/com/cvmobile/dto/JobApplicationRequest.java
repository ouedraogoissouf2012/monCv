package com.cvmobile.dto;

import com.cvmobile.model.JobApplicationStatus;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.time.LocalDate;

@Data
public class JobApplicationRequest {
    private Long cvId;

    @NotBlank(message = "L'entreprise est obligatoire")
    @Size(max = 200, message = "L'entreprise ne doit pas depasser 200 caracteres")
    private String company;

    @NotBlank(message = "Le poste est obligatoire")
    @Size(max = 200, message = "Le poste ne doit pas depasser 200 caracteres")
    private String position;

    @Size(max = 500, message = "Le lien ne doit pas depasser 500 caracteres")
    private String offerUrl;

    @NotNull(message = "Le statut est obligatoire")
    private JobApplicationStatus status;

    private LocalDate sentDate;
    private LocalDate nextFollowUp;

    @Size(max = 10000, message = "Les notes ne doivent pas depasser 10000 caracteres")
    private String notes;
}
