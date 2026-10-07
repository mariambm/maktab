package com.maktab.classgroup.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record ClassRequest(
        @NotBlank(message = "Name is required") @Size(max = 100, message = "Name is too long")
        String name,
        @NotNull(message = "Choose a curriculum level")
        UUID curriculumLevelId,
        @Size(max = 50, message = "Room is too long")
        String room,
        /** Defaults to true when omitted. */
        Boolean active) {
}
