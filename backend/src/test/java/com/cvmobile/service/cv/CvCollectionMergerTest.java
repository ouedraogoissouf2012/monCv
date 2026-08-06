package com.cvmobile.service.cv;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CvCollectionMergerTest {

    @Mock private CvMapper cvMapper;

    @InjectMocks
    private CvCollectionMerger merger;

    @Test
    void mergeCollections_metAJourInsereEtSupprimeSelonLesIds() {
        Cv cv = Cv.builder().id(10L).titre("CV").build();
        Experience existing1 = Experience.builder().id(1L).poste("A").description("old").build();
        Experience existing2 = Experience.builder().id(2L).poste("B").description("a supprimer").build();
        cv.addExperience(existing1);
        cv.addExperience(existing2);

        CvRequest.ExperienceDto updateDto =
                CvRequest.ExperienceDto.builder().id(1L).poste("A").description("updated").build();
        CvRequest.ExperienceDto insertDto =
                CvRequest.ExperienceDto.builder().poste("C").description("nouveau").build();
        Experience inserted = Experience.builder().poste("C").description("nouveau").build();

        CvRequest request = CvRequest.builder()
                .experiences(List.of(updateDto, insertDto))
                .build();
        when(cvMapper.toExperience(insertDto)).thenReturn(inserted);

        merger.mergeCollections(cv, request);

        // existing2 supprime (id absent de la requete), existing1 conserve, insert ajoute.
        assertThat(cv.getExperiences())
                .containsExactlyInAnyOrder(existing1, inserted)
                .doesNotContain(existing2);
        verify(cvMapper).updateExperience(updateDto, existing1);
        verify(cvMapper).toExperience(insertDto);
    }

    @Test
    void mergeCollections_videLaCollectionQuandLaListeEstNulle() {
        Cv cv = Cv.builder().id(10L).titre("CV").build();
        cv.addExperience(Experience.builder().id(1L).poste("A").build());

        // request sans aucune collection (toutes nulles)
        CvRequest request = CvRequest.builder().build();

        merger.mergeCollections(cv, request);

        assertThat(cv.getExperiences()).isEmpty();
    }
}
