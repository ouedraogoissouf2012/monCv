package com.cvmobile.cv.adapter.in.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
@DisplayName("CvResponseAssembler")
class CvResponseAssemblerTest {

    private static final long OWNER = 7L;

    @Mock private CvRepository cvRepository;
    @Mock private CvMapper cvMapper;

    private CvResponseAssembler assembler;

    @BeforeEach
    void setUp() {
        assembler = new CvResponseAssembler(cvRepository, cvMapper);
    }

    private com.cvmobile.model.Cv entity(long id, Long parentId) {
        var builder = com.cvmobile.model.Cv.builder()
                .id(id).titre("CV" + id).user(User.builder().id(OWNER).build());
        if (parentId != null) {
            builder.parent(com.cvmobile.model.Cv.builder().id(parentId).build())
                    .varianteLabel("Backend");
        }
        return builder.build();
    }

    @Test
    @DisplayName("assemble construit la reponse depuis l'entite possedee")
    void assembles() {
        var e = entity(10L, null);
        when(cvRepository.findByIdAndUserId(10L, OWNER)).thenReturn(Optional.of(e));
        when(cvMapper.toResponse(e)).thenReturn(CvResponse.builder().id(10L).build());

        assertThat(assembler.assemble(10L, OWNER).getId()).isEqualTo(10L);
    }

    @Test
    @DisplayName("assemble echoue en 404 (CvNotFoundException) si l'entite a disparu")
    void assembleFailsWhenEntityGone() {
        when(cvRepository.findByIdAndUserId(10L, OWNER)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> assembler.assemble(10L, OWNER))
                .isInstanceOf(com.cvmobile.cv.application.CvNotFoundException.class);
    }

    @Test
    @DisplayName("assembleAll enrichit le nombre de variantes des CV parents")
    void assembleAllEnrichesVariantCount() {
        var parent = entity(1L, null);
        var variant = entity(2L, 1L);
        when(cvRepository.findByUserIdWithDetails(OWNER))
                .thenReturn(List.of(parent, variant));
        when(cvMapper.toResponse(parent)).thenReturn(CvResponse.builder().id(1L).build());
        when(cvMapper.toResponse(variant)).thenReturn(CvResponse.builder().id(2L).build());
        when(cvRepository.countVariantsByParentIds(List.of(1L)))
                .thenReturn(List.<Object[]>of(new Object[]{1L, 3L}));

        List<CvResponse> responses = assembler.assembleAll(OWNER);

        assertThat(responses).hasSize(2);
        assertThat(responses.stream().filter(r -> r.getId() == 1L).findFirst().orElseThrow()
                .getVariantCount()).isEqualTo(3);
    }

    @Test
    @DisplayName("assembleAll sans CV parent n'interroge pas le compteur de variantes")
    void assembleAllNoParents() {
        var variant = entity(2L, 1L);
        when(cvRepository.findByUserIdWithDetails(OWNER)).thenReturn(List.of(variant));
        when(cvMapper.toResponse(variant)).thenReturn(CvResponse.builder().id(2L).build());

        assertThat(assembler.assembleAll(OWNER)).hasSize(1);
    }
}
