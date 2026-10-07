package com.maktab.lesson.api;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/** One student's attendance in the register. Minutes late are required for LATE and only allowed there. */
public record AttendanceEntryRequest(
        @NotNull(message = "Student is required") UUID studentId,
        @NotNull(message = "Attendance is required") AttendanceStatus status,
        @Min(value = 1, message = "Minutes late must be at least 1")
        @Max(value = 300, message = "Minutes late is too high") Integer minutesLate,
        AbsenceReason absenceReason,
        @Size(max = 500, message = "Note is too long") String note) {

    @JsonIgnore
    @AssertTrue(message = "Enter how many minutes late the student was")
    public boolean isMinutesLateConsistent() {
        return (status == AttendanceStatus.LATE) == (minutesLate != null);
    }

    @JsonIgnore
    @AssertTrue(message = "Only an absent student can have an absence reason")
    public boolean isAbsenceReasonConsistent() {
        return status == AttendanceStatus.ABSENT || absenceReason == null;
    }
}
