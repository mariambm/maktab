package com.maktab.classgroup.api;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateCurriculumLevelRequest(
        @NotBlank(message = "Name is required") @Size(max = 100, message = "Name is too long")
        String name,
        @Min(value = 0, message = "Order must be 0 or more") @Max(value = 999, message = "Order must be 999 or less")
        Integer sortOrder) {
}
