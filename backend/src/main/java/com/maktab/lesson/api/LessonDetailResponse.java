package com.maktab.lesson.api;

import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.api.LessonTopicResponse;
import com.maktab.lesson.domain.LessonStatus;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Everything the lesson screen needs in one request: the lesson, its register, this week's curriculum topics and
 * which of them were covered.
 */
public record LessonDetailResponse(
        UUID id,
        UUID classGroupId,
        String className,
        String room,
        LocalDate lessonDate,
        LocalTime startTime,
        LocalTime endTime,
        LessonStatus status,
        String contentNotes,
        UUID teacherUserId,
        CurriculumPeriodSummary curriculumPeriod,
        Integer curriculumWeekNumber,
        List<LessonTopicResponse> availableTopics,
        List<UUID> coveredTopicIds,
        List<LessonStudentResponse> students) {
}
