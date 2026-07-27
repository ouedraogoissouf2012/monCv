package com.cvmobile.cv.adapter.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
@DisplayName("CvPersistenceAdapter")
class CvPersistenceAdapterTest {

    private static final long OWNER = 7L;

    @Mock private CvRepository cvRepository;
    @Mock private UserRepository userRepository;

    private CvPersistenceAdapter adapter;

    @BeforeEach
    void setUp() {
        adapter = new CvPersistenceAdapter(
                cvRepository, userRepository, new CvPersistenceMapper());
    }

    private com.cvmobile.model.Cv persisted(long id) {
        return com.cvmobile.model.Cv.builder()
                .id(id).titre("Existant").user(User.builder().id(OWNER).build())
                .build();
    }

    @Test
    @DisplayName("save d'un CV neuf reference le proprietaire par proxy et persiste")
    void savesNewCv() {
        User ref = User.builder().id(OWNER).build();
        when(userRepository.getReferenceById(OWNER)).thenReturn(ref);
        when(cvRepository.save(any())).thenAnswer(inv -> {
            com.cvmobile.model.Cv e = inv.getArgument(0);
            e.setId(55L);
            return e;
        });

        Cv result = adapter.save(Cv.create("Nouveau", OWNER));

        ArgumentCaptor<com.cvmobile.model.Cv> captor =
                ArgumentCaptor.forClass(com.cvmobile.model.Cv.class);
        verify(cvRepository).save(captor.capture());
        assertThat(captor.getValue().getUser()).isSameAs(ref);
        assertThat(captor.getValue().getTitre()).isEqualTo("Nouveau");
        assertThat(result.getId()).isEqualTo(55L);
        verify(cvRepository, never()).findByIdAndUserId(anyLong(), anyLong());
    }

    @Test
    @DisplayName("save d'une variante neuve pose la reference parent")
    void savesNewVariantWithParentReference() {
        User ref = User.builder().id(OWNER).build();
        com.cvmobile.model.Cv parentRef = com.cvmobile.model.Cv.builder().id(100L).build();
        when(userRepository.getReferenceById(OWNER)).thenReturn(ref);
        when(cvRepository.getReferenceById(100L)).thenReturn(parentRef);
        when(cvRepository.save(any())).thenAnswer(inv -> {
            com.cvmobile.model.Cv e = inv.getArgument(0);
            e.setId(56L);
            return e;
        });

        adapter.save(Cv.createVariant("Parent — Backend", OWNER, 100L, "Backend"));

        ArgumentCaptor<com.cvmobile.model.Cv> captor =
                ArgumentCaptor.forClass(com.cvmobile.model.Cv.class);
        verify(cvRepository).save(captor.capture());
        assertThat(captor.getValue().getParent()).isSameAs(parentRef);
        assertThat(captor.getValue().getVarianteLabel()).isEqualTo("Backend");
    }

    @Test
    @DisplayName("save d'un CV existant recharge en verifiant l'appartenance")
    void savesExistingCvWithOwnershipCheck() {
        com.cvmobile.model.Cv existing = persisted(42L);
        existing.setPublicToken("secret");
        when(cvRepository.findByIdAndUserId(42L, OWNER)).thenReturn(Optional.of(existing));
        when(cvRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Cv toUpdate = Cv.rehydrate(
                42L, "Renomme", OWNER, com.cvmobile.cv.domain.model.CvStyle.defaults(),
                null, null, 0, 0, 0);
        adapter.save(toUpdate);

        verify(cvRepository).findByIdAndUserId(42L, OWNER);
        assertThat(existing.getTitre()).isEqualTo("Renomme");
        assertThat(existing.getPublicToken()).isEqualTo("secret");
        verify(userRepository, never()).getReferenceById(anyLong());
    }

    @Test
    @DisplayName("save d'un CV existant absent pour ce proprietaire echoue")
    void savingUnownedCvFails() {
        when(cvRepository.findByIdAndUserId(42L, OWNER)).thenReturn(Optional.empty());
        Cv toUpdate = Cv.rehydrate(
                42L, "X", OWNER, com.cvmobile.cv.domain.model.CvStyle.defaults(),
                null, null, 0, 0, 0);

        assertThatThrownBy(() -> adapter.save(toUpdate))
                .isInstanceOf(IllegalStateException.class);
        verify(cvRepository, never()).save(any());
    }

    @Test
    @DisplayName("findByIdAndOwnerId convertit en domaine")
    void findsById() {
        when(cvRepository.findByIdAndUserId(42L, OWNER))
                .thenReturn(Optional.of(persisted(42L)));

        Optional<Cv> result = adapter.findByIdAndOwnerId(42L, OWNER);

        assertThat(result).isPresent();
        assertThat(result.get().getOwnerId()).isEqualTo(OWNER);
    }

    @Test
    @DisplayName("findAllByOwnerId mappe la liste complete")
    void findsAll() {
        when(cvRepository.findByUserIdWithDetails(OWNER))
                .thenReturn(List.of(persisted(1L), persisted(2L)));

        assertThat(adapter.findAllByOwnerId(OWNER)).hasSize(2);
    }

    @Test
    @DisplayName("deleteByIdAndOwnerId supprime uniquement un CV possede")
    void deletesOwned() {
        when(cvRepository.existsByIdAndUserId(42L, OWNER)).thenReturn(true);

        boolean deleted = adapter.deleteByIdAndOwnerId(42L, OWNER);

        assertThat(deleted).isTrue();
        verify(cvRepository).deleteById(42L);
    }

    @Test
    @DisplayName("deleteByIdAndOwnerId ne supprime pas un CV non possede")
    void doesNotDeleteUnowned() {
        when(cvRepository.existsByIdAndUserId(42L, OWNER)).thenReturn(false);

        boolean deleted = adapter.deleteByIdAndOwnerId(42L, OWNER);

        assertThat(deleted).isFalse();
        verify(cvRepository, never()).deleteById(anyLong());
    }
}
