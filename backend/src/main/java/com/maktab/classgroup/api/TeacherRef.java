package com.maktab.classgroup.api;

import com.maktab.user.domain.User;
import java.util.UUID;

public record TeacherRef(UUID id, String firstName, String lastName) {

    public static TeacherRef from(User user) {
        return new TeacherRef(user.getId(), user.getFirstName(), user.getLastName());
    }
}
