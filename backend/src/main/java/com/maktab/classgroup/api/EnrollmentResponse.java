package com.maktab.classgroup.api;

import java.time.LocalDate;
import java.util.UUID;

/** One period in a student's class history. {@code endDate} is exclusive and null for the current class. */
public record EnrollmentResponse(UUID id, ClassRef classGroup, LocalDate startDate, LocalDate endDate) {
}
