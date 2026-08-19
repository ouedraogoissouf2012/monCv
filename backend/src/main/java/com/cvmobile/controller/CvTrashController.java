package com.cvmobile.controller;

import com.cvmobile.cv.adapter.in.web.CvResponseAssembler;
import com.cvmobile.cv.application.usecase.CvTrashUseCase;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cvs/trash")
@RequiredArgsConstructor
@Tag(name = "CV", description = "Corbeille des CV")
@SecurityRequirement(name = "bearerAuth")
public class CvTrashController {

    private final CvTrashUseCase trashUseCase;
    private final CvResponseAssembler cvResponseAssembler;

    @GetMapping
    @Operation(summary = "Lister les CV en corbeille")
    public List<CvResponse> list(@AuthenticationPrincipal User user) {
        return cvResponseAssembler.assembleTrash(user.getId());
    }

    @PostMapping("/{id}/restore")
    @Operation(summary = "Restaurer un CV depuis la corbeille")
    public ResponseEntity<CvResponse> restore(
            @PathVariable Long id, @AuthenticationPrincipal User user) {
        trashUseCase.restore(id, user.getId());
        return ResponseEntity.ok(cvResponseAssembler.assemble(id, user.getId()));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Supprimer definitivement un CV")
    public ResponseEntity<Void> purge(
            @PathVariable Long id, @AuthenticationPrincipal User user) {
        trashUseCase.purge(id, user.getId());
        return ResponseEntity.noContent().build();
    }
}
