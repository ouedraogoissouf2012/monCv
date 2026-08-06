package com.cvmobile.service.cv;

import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CvFinderTest {

    @Mock private CvRepository cvRepository;

    @InjectMocks
    private CvFinder cvFinder;

    @Test
    void findByIdAndUserId_existant_retourneLeCv() {
        Cv cv = Cv.builder().id(10L).titre("CV").build();
        when(cvRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(cv));

        assertThat(cvFinder.findByIdAndUserId(10L, 1L)).isSameAs(cv);
    }

    @Test
    void findByIdAndUserId_inconnu_leveResourceNotFound() {
        when(cvRepository.findByIdAndUserId(99L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> cvFinder.findByIdAndUserId(99L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
    }
}
