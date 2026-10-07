package com.maktab.behaviour.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.behaviour.api.BehaviourEntryRequest;
import com.maktab.behaviour.api.LessonBehaviourResponse;
import com.maktab.behaviour.api.RecordBehaviourRequest;
import com.maktab.behaviour.api.StudentBehaviourResponse;
import com.maktab.behaviour.domain.Behaviour;
import com.maktab.behaviour.domain.BehaviourRecord;
import com.maktab.behaviour.persistence.BehaviourRecordRepository;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.lesson.application.LessonAccess;
import com.maktab.lesson.domain.Lesson;
import com.maktab.student.application.StudentAccess;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Behaviour observed per lesson. Every observation belongs to one lesson and date; none is a lasting label. */
@Service
public class BehaviourService {

    private final BehaviourRecordRepository records;
    private final ClassGroupRepository classes;
    private final LessonAccess lessons;
    private final StudentAccess students;
    private final AuditService audit;

    public BehaviourService(BehaviourRecordRepository records, ClassGroupRepository classes, LessonAccess lessons,
            StudentAccess students, AuditService audit) {
        this.records = records;
        this.classes = classes;
        this.lessons = lessons;
        this.students = students;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public LessonBehaviourResponse forLesson(CurrentUser actor, UUID lessonId) {
        Lesson lesson = lessons.loadInScope(actor, lessonId);
        return toResponse(lesson.getId());
    }

    /** Replaces the lesson's observations with what was sent. */
    @Transactional
    public LessonBehaviourResponse record(CurrentUser actor, UUID lessonId, RecordBehaviourRequest request) {
        Lesson lesson = lessons.loadInScope(actor, lessonId);
        lessons.requireOnRoster(lesson, request.entries().stream().map(BehaviourEntryRequest::studentId).toList());
        Map<UUID, BehaviourRecord> existing = records.findByLessonId(lessonId).stream()
                .collect(Collectors.toMap(BehaviourRecord::getStudentId, Function.identity()));
        int recorded = 0;
        for (BehaviourEntryRequest entry : request.entries()) {
            String note = blankToNull(entry.note());
            if (entry.behavioursOrEmpty().isEmpty() && note == null) {
                continue;
            }
            BehaviourRecord record = existing.remove(entry.studentId());
            boolean isNew = record == null;
            if (isNew) {
                record = new BehaviourRecord(lessonId, entry.studentId());
            }
            record.record(entry.behavioursOrEmpty(), note, actor.id());
            if (isNew) {
                records.save(record);
            }
            recorded++;
        }
        // Whoever is left (left out, or sent with nothing selected) no longer has observations for this lesson.
        records.deleteAll(existing.values());
        records.flush();
        audit.record(actor, AuditAction.BEHAVIOUR_RECORDED, "Lesson", lessonId, null, Map.of("students", recorded));
        return toResponse(lessonId);
    }

    @Transactional(readOnly = true)
    public List<StudentBehaviourResponse> forStudent(CurrentUser actor, UUID studentId) {
        students.requireInScope(actor, studentId);
        List<BehaviourRecordRepository.StudentBehaviourRow> rows = records.findForStudent(studentId);
        Map<UUID, String> classNames = classNames(rows.stream()
                .map(BehaviourRecordRepository.StudentBehaviourRow::getClassGroupId).collect(Collectors.toSet()));
        return rows.stream().map(row -> new StudentBehaviourResponse(row.getRecord().getLessonId(),
                row.getLessonDate(), row.getClassGroupId(), classNames.get(row.getClassGroupId()),
                sorted(row.getRecord().getBehaviours()), row.getRecord().getNote())).toList();
    }

    private LessonBehaviourResponse toResponse(UUID lessonId) {
        return new LessonBehaviourResponse(lessonId, records.findByLessonId(lessonId).stream()
                .map(r -> new LessonBehaviourResponse.Observation(r.getStudentId(), sorted(r.getBehaviours()),
                        r.getNote()))
                .toList());
    }

    private Map<UUID, String> classNames(Collection<UUID> ids) {
        return classes.findByIdIn(ids).stream().collect(Collectors.toMap(ClassGroup::getId, ClassGroup::getName));
    }

    /** In the order the mosque listed them: good behaviour first. */
    private static List<Behaviour> sorted(Collection<Behaviour> behaviours) {
        return behaviours.stream().sorted().toList();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
