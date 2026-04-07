package com.cvmobile.mapper;

import com.cvmobile.dto.AuthResponse;
import com.cvmobile.dto.RegisterRequest;
import com.cvmobile.model.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

/**
 * MapStruct mapper pour les conversions User.
 * - User -> AuthResponse.UserDto (lecture profil)
 * - RegisterRequest -> User (inscription, mot de passe encode separement)
 */
@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "role", source = "role", qualifiedByName = "roleToString")
    AuthResponse.UserDto toUserDto(User user);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "password", ignore = true)
    @Mapping(target = "role", constant = "USER")
    @Mapping(target = "cvs", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    User toUser(RegisterRequest request);

    @Named("roleToString")
    default String roleToString(User.Role role) {
        return role != null ? role.name() : null;
    }
}
