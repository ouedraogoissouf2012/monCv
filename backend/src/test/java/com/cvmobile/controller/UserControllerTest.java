package com.cvmobile.controller;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.UpdateProfileRequest;
import com.cvmobile.mapper.UserMapper;
import com.cvmobile.model.User;
import com.cvmobile.service.cv.ICvService;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/// Tests unitaires d'UserController (issue #258) : le compte cible est toujours
/// l'utilisateur AUTHENTIFIE ; mise a jour partielle du profil ; export et
/// suppression.
class UserControllerTest {

    private final IUserService userService = mock(IUserService.class);
    private final UserMapper userMapper = mock(UserMapper.class);
    private final ICvService cvService = mock(ICvService.class);
    private final UserController controller =
            new UserController(userService, userMapper, cvService);

    @Test
    void getCurrentUser_retourneLeProfilMappe() {
        User user = User.builder().id(1L).build();
        AuthResponse.UserDto dto = mock(AuthResponse.UserDto.class);
        when(userMapper.toUserDto(user)).thenReturn(dto);

        ResponseEntity<AuthResponse.UserDto> response =
                controller.getCurrentUser(user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isSameAs(dto);
    }

    @Test
    void updateCurrentUser_appliqueNomEtPrenomPuisSauvegarde() {
        User user = User.builder().id(1L).nom("Ancien").prenom("Vieux").build();
        AuthResponse.UserDto dto = mock(AuthResponse.UserDto.class);
        when(userService.save(user)).thenReturn(user);
        when(userMapper.toUserDto(user)).thenReturn(dto);

        UpdateProfileRequest request = new UpdateProfileRequest();
        request.setNom("Nouveau");
        request.setPrenom("Neuf");
        ResponseEntity<AuthResponse.UserDto> response =
                controller.updateCurrentUser(user, request);

        assertThat(user.getNom()).isEqualTo("Nouveau");
        assertThat(user.getPrenom()).isEqualTo("Neuf");
        assertThat(response.getBody()).isSameAs(dto);
        verify(userService).save(user);
    }

    @Test
    void updateCurrentUser_miseAJourPartielle_laisseLesAutresChampsIntacts() {
        User user = User.builder().id(1L).nom("Ancien").prenom("Vieux").build();
        when(userService.save(user)).thenReturn(user);
        when(userMapper.toUserDto(user)).thenReturn(mock(AuthResponse.UserDto.class));

        UpdateProfileRequest partial = new UpdateProfileRequest();
        partial.setNom("Nouveau");
        controller.updateCurrentUser(user, partial);

        assertThat(user.getNom()).isEqualTo("Nouveau");
        assertThat(user.getPrenom()).isEqualTo("Vieux"); // non fourni -> inchange
    }

    @Test
    void exportCurrentUser_assembleProfilEtCvsAvecMetadonnees() {
        User user = User.builder().id(7L).build();
        AuthResponse.UserDto dto = mock(AuthResponse.UserDto.class);
        List<CvResponse> cvs = List.of();
        when(userMapper.toUserDto(user)).thenReturn(dto);
        when(cvService.getAllCvsByUserId(7L)).thenReturn(cvs);

        ResponseEntity<Map<String, Object>> response =
                controller.exportCurrentUser(user);

        Map<String, Object> body = response.getBody();
        assertThat(body).isNotNull();
        assertThat(body.get("profile")).isSameAs(dto);
        assertThat(body.get("cvs")).isEqualTo(cvs);
        assertThat(body.get("cvCount")).isEqualTo(0);
        assertThat(body).containsKey("exportedAt");
        assertThat(body.get("notice")).asString().contains("MonCV");
    }

    @Test
    void deleteCurrentUser_supprimeLeCompteAuthentifieEtRetourne204() {
        User user = User.builder().id(3L).build();

        ResponseEntity<Void> response = controller.deleteCurrentUser(user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(userService).deleteById(3L);
    }
}
