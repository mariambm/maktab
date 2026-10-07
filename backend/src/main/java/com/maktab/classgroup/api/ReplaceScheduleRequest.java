package com.maktab.classgroup.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record ReplaceScheduleRequest(
        @NotNull(message = "Slots are required") @Size(max = 14, message = "Too many slots")
        List<@NotNull @Valid ScheduleSlot> slots) {
}
