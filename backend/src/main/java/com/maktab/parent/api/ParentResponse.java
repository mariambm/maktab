package com.maktab.parent.api;

import java.util.List;
import java.util.UUID;

public record ParentResponse(
        UUID id,
        String firstName,
        String lastName,
        String phone,
        String email,
        List<ParentChildResponse> children) {
}
