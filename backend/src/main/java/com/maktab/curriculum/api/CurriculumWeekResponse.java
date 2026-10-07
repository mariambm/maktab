package com.maktab.curriculum.api;

import java.util.List;
import java.util.UUID;

public record CurriculumWeekResponse(UUID id, int weekNumber, boolean review, List<LessonTopicResponse> topics) {
}
