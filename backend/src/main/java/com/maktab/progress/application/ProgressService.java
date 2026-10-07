package com.maktab.progress.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.common.BusinessValidationException;
import com.maktab.lesson.application.LessonAccess;
import com.maktab.lesson.domain.Lesson;
import com.maktab.progress.api.LessonProgressResponse;
import com.maktab.progress.api.ProgressEntryRequest;
import com.maktab.progress.api.ProgressScaleLevelResponse;
import com.maktab.progress.api.RecordProgressRequest;
import com.maktab.progress.api.StudentProgressResponse;
import com.maktab.progress.domain.ProgressScaleLevel;
import com.maktab.progress.domain.StudentProgress;
import com.maktab.progress.persistence.ProgressScaleLevelRepository;
import com.maktab.progress.persistence.StudentProgressRepository;
import com.maktab.student.application.StudentAccess;
import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Progress scores per lesson and subject, on the organisation's own scale. Reads and writes go through the lesson
 * or student scope, so a teacher only reaches the students of their own classes.
 */
@Service
public class ProgressService {

    private final StudentProgressRepository progress;
    private final ProgressScaleLevelRepository scale;
    private final ClassGroupRepository classes;
    private final LessonAccess lessons;
    private final StudentAccess students;
    private final AuditService audit;

    public ProgressService(StudentProgressRepository progress, ProgressScaleLevelRepository scale,
            ClassGroupRepository classes, LessonAccess lessons, StudentAccess students, AuditService audit) {
        this.progress = progress;
        this.scale = scale;
        this.classes = classes;
        this.lessons = lessons;
        this.students = students;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public List<ProgressScaleLevelResponse> scale(CurrentUser actor) {
        return scale.findByOrganisationIdOrderByScore(actor.organisationId()).stream()
                .map(level -> new ProgressScaleLevelResponse(level.getScore(), level.getLabel())).toList();
    }

    @Transactional(readOnly = true)
    public LessonProgressResponse forLesson(CurrentUser actor, UUID lessonId) {
        Lesson lesson = lessons.loadInScope(actor, lessonId);
        return toResponse(lesson.getId());
    }

    /** Replaces the scores of one subject in a lesson with what was sent. */
    @Transactional
    public LessonProgressResponse record(CurrentUser actor, UUID lessonId, RecordProgressRequest request) {
        Lesson lesson = lessons.loadInScope(actor, lessonId);
        lessons.requireOnRoster(lesson, request.entries().stream().map(ProgressEntryRequest::studentId).toList());
        Map<BigDecimal, ProgressScaleLevel> levels = levelsByScore(actor.organisationId());
        for (ProgressEntryRequest entry : request.entries()) {
            if (!levels.containsKey(normalise(entry.score()))) {
                throw new BusinessValidationException("entries", "A score is not on the progress scale");
            }
        }
        Map<UUID, StudentProgress> existing = progress.findByLessonIdAndSubject(lessonId, request.subject()).stream()
                .collect(Collectors.toMap(StudentProgress::getStudentId, Function.identity()));
        for (ProgressEntryRequest entry : request.entries()) {
            StudentProgress record = existing.remove(entry.studentId());
            boolean isNew = record == null;
            if (isNew) {
                record = new StudentProgress(lessonId, entry.studentId(), request.subject());
            }
            record.record(levels.get(normalise(entry.score())).getScore(), blankToNull(entry.note()), actor.id());
            if (isNew) {
                // Saved once complete: a new row is inserted with the state it has at save time.
                progress.save(record);
            }
        }
        // Whoever is left had a score for this subject and no longer does.
        progress.deleteAll(existing.values());
        progress.flush();
        audit.record(actor, AuditAction.PROGRESS_RECORDED, "Lesson", lessonId, null,
                Map.of("subject", request.subject(), "students", request.entries().size()));
        return toResponse(lessonId);
    }

    @Transactional(readOnly = true)
    public List<StudentProgressResponse> forStudent(CurrentUser actor, UUID studentId) {
        students.requireInScope(actor, studentId);
        List<StudentProgressRepository.StudentProgressRow> rows = progress.findForStudent(studentId);
        Map<UUID, String> classNames = classes.findByIdIn(rows.stream()
                        .map(StudentProgressRepository.StudentProgressRow::getClassGroupId)
                        .collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(ClassGroup::getId, ClassGroup::getName));
        Map<BigDecimal, ProgressScaleLevel> levels = levelsByScore(actor.organisationId());
        return rows.stream().map(row -> {
            ProgressScaleLevel level = levels.get(normalise(row.getScore()));
            return new StudentProgressResponse(row.getLessonId(), row.getLessonDate(), row.getClassGroupId(),
                    classNames.get(row.getClassGroupId()), row.getSubject(), row.getScore(),
                    level == null ? null : level.getLabel(), row.getNote());
        }).toList();
    }

    private LessonProgressResponse toResponse(UUID lessonId) {
        List<LessonProgressResponse.Score> scores = progress.findByLessonId(lessonId).stream()
                .sorted(Comparator.comparing(StudentProgress::getSubject))
                .map(p -> new LessonProgressResponse.Score(p.getStudentId(), p.getSubject(), p.getScore(),
                        p.getNote()))
                .toList();
        return new LessonProgressResponse(lessonId, scores);
    }

    private Map<BigDecimal, ProgressScaleLevel> levelsByScore(UUID organisationId) {
        return scale.findByOrganisationIdOrderByScore(organisationId).stream()
                .collect(Collectors.toMap(level -> normalise(level.getScore()), Function.identity()));
    }

    /** 4, 4.0 and 4.00 are the same score. */
    private static BigDecimal normalise(BigDecimal score) {
        return score.stripTrailingZeros();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
