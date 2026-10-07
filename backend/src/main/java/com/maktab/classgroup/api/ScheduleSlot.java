package com.maktab.classgroup.api;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.maktab.classgroup.domain.ClassSchedule;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import java.time.DayOfWeek;
import java.time.LocalTime;

/** A weekly slot, used in both requests and responses. Times are local to the organisation's time zone. */
public record ScheduleSlot(
        @NotNull(message = "Day is required") DayOfWeek weekday,
        @NotNull(message = "Start time is required") LocalTime startTime,
        @NotNull(message = "End time is required") LocalTime endTime) {

    public static ScheduleSlot from(ClassSchedule slot) {
        return new ScheduleSlot(slot.getWeekday(), slot.getStartTime(), slot.getEndTime());
    }

    @JsonIgnore
    @AssertTrue(message = "End time must be after start time")
    public boolean isEndAfterStart() {
        return startTime == null || endTime == null || endTime.isAfter(startTime);
    }
}
