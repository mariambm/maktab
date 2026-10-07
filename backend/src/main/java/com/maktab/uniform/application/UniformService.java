package com.maktab.uniform.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.lesson.application.LessonAccess;
import com.maktab.lesson.domain.Lesson;
import com.maktab.student.application.StudentAccess;
import com.maktab.uniform.api.LessonUniformResponse;
import com.maktab.uniform.api.RecordUniformRequest;
import com.maktab.uniform.api.StudentUniformResponse;
import com.maktab.uniform.api.UniformEntryRequest;
import com.maktab.uniform.domain.UniformRecord;
import com.maktab.uniform.persistence.UniformRecordRepository;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Uniform observations per lesson; each is about that day only. */
@Service
public class UniformService {

    private final UniformRecordRepository records;
    private final ClassGroupRepository classes;
    private final LessonAccess lessons;
    private final StudentAccess students;
    private final AuditService audit;

    public UniformService(UniformRecordRepository records, ClassGroupRepository classes, LessonAccess lessons,
            StudentAccess students, AuditService audit) {
        this.records = records;
        this.classes = classes;
        this.lessons = lessons;
        this.students = students;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public LessonUniformResponse forLesson(CurrentUser actor, UUID lessonId) {
        Lesson lesson = lessons.loadInScope(actor, lessonId);
        return toResponse(lesson.getId());
    }

    /** Replaces the lesson's uniform records with what was sent. */
    @Transactional
    public LessonUniformResponse record(CurrentUser actor, UUID lessonId, RecordUniformRequest request) {
        Lesson lesson = lessons.loadInScope(actor, lessonId);
        lessons.requireOnRoster(lesson, request.entries().stream().map(UniformEntryRequest::studentId).toList());
        Map<UUID, UniformRecord> existing = records.findByLessonId(lessonId).stream()
                .collect(Collectors.toMap(UniformRecord::getStudentId, Function.identity()));
        for (UniformEntryRequest entry : request.entries()) {
            UniformRecord record = existing.remove(entry.studentId());
            boolean isNew = record == null;
            if (isNew) {
                record = new UniformRecord(lessonId, entry.studentId());
            }
            record.record(entry.status(), entry.reason(), blankToNull(entry.note()), actor.id());
            if (isNew) {
                records.save(record);
            }
        }
        records.deleteAll(existing.values());
        records.flush();
        audit.record(actor, AuditAction.UNIFORM_RECORDED, "Lesson", lessonId, null,
                Map.of("students", request.entries().size()));
        return toResponse(lessonId);
    }

    @Transactional(readOnly = true)
    public List<StudentUniformResponse> forStudent(CurrentUser actor, UUID studentId) {
        students.requireInScope(actor, studentId);
        List<UniformRecordRepository.StudentUniformRow> rows = records.findForStudent(studentId);
        Map<UUID, String> classNames = classes.findByIdIn(rows.stream()
                        .map(UniformRecordRepository.StudentUniformRow::getClassGroupId)
                        .collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(ClassGroup::getId, ClassGroup::getName));
        return rows.stream().map(row -> {
            UniformRecord r = row.getRecord();
            return new StudentUniformResponse(r.getLessonId(), row.getLessonDate(), row.getClassGroupId(),
                    classNames.get(row.getClassGroupId()), r.getStatus(), r.getReason(), r.getNote());
        }).toList();
    }

    private LessonUniformResponse toResponse(UUID lessonId) {
        return new LessonUniformResponse(lessonId, records.findByLessonId(lessonId).stream()
                .map(r -> new LessonUniformResponse.Entry(r.getStudentId(), r.getStatus(), r.getReason(),
                        r.getNote()))
                .toList());
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
