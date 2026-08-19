package com.cvmobile.controller;

import com.cvmobile.cv.adapter.in.web.CvResponseAssembler;
import com.cvmobile.cv.application.usecase.CvTrashUseCase;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.User;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CvTrashControllerTest {

    @Mock private CvTrashUseCase trashUseCase;
    @Mock private CvResponseAssembler assembler;
    @InjectMocks private CvTrashController controller;

    @Test
    void listReturnsAssemblerTrash() {
        User user = User.builder().id(3L).build();
        when(assembler.assembleTrash(3L)).thenReturn(List.of(CvResponse.builder().id(9L).build()));

        assertThat(controller.list(user)).extracting(CvResponse::getId).containsExactly(9L);
    }

    @Test
    void restoreDelegatesThenAssembles() {
        User user = User.builder().id(3L).build();
        when(assembler.assemble(8L, 3L)).thenReturn(CvResponse.builder().id(8L).build());

        assertThat(controller.restore(8L, user).getBody().getId()).isEqualTo(8L);
        verify(trashUseCase).restore(8L, 3L);
    }

    @Test
    void purgeReturnsNoContent() {
        User user = User.builder().id(3L).build();

        assertThat(controller.purge(8L, user).getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(trashUseCase).purge(8L, 3L);
    }
}
