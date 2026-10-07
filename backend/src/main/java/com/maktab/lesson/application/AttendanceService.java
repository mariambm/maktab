package com.maktab.lesson.application;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.NotFoundException;
import com.maktab.lesson.api.AttendanceStatisticsResponse;
import com.maktab.lesson.api.StudentAttendanceResponse;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.lesson.persistence.LessonAttendanceRepository;
import com.maktab.organisation.domain.Organisation;
import com.maktab.organisation.persistence.OrganisationRepository;
import com.maktab.student.persistence.StudentRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * A student's attendance history and the figures derived from it. Nothing here is stored: percentages and counts
 * are calculated per request from the attendance rows.
 */
@Service
public class AttendanceService {

    private final LessonAttendanceRepository attendance;
    private final StudentRepository students;
    private final ClassGroupRepository classes;
    private final OrganisationRepository organisations;
    private final AccessScopeService scopes;

    public AttendanceService(LessonAttendanceRepository attendance, StudentRepository students,
            ClassGroupRepository classes, OrganisationRepository organisations, AccessScopeService scopes) {
        this.attendance = attendance;
        this.students = students;
        this.classes = classes;
        this.organisations = organisations;
        this.scopes = scopes;
    }

    @Transactional(readOnly = true)
    public List<StudentAttendanceResponse> forStudent(CurrentUser actor, UUID studentId, LocalDate from,
            LocalDate to) {
        requireStudentInScope(actor, studentId);
        List<LessonAttendanceRepository.StudentAttendanceRow> rows =
                attendance.findForStudent(studentId, from, to);
        Map<UUID, ClassGroup> classById = classes.findByIdIn(rows.stream()
                        .map(LessonAttendanceRepository.StudentAttendanceRow::getClassGroupId)
                        .collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(ClassGroup::getId, Function.identity()));
        return rows.stream().map(row -> new StudentAttendanceResponse(row.getLessonId(), row.getLessonDate(),
                row.getClassGroupId(),
                classById.containsKey(row.getClassGroupId()) ? classById.get(row.getClassGroupId()).getName() : null,
                row.getStatus(), row.getMinutesLate() == null ? null : (int) row.getMinutesLate(),
                row.getAbsenceReason(), row.getNote())).toList();
    }

    @Transactional(readOnly = true)
    public AttendanceStatisticsResponse statisticsForStudent(CurrentUser actor, UUID studentId, LocalDate from,
            LocalDate to) {
        requireStudentInScope(actor, studentId);
        Map<AttendanceStatus, Long> counts = attendance.countByStatus(Set.of(studentId), from, to).stream()
                .collect(Collectors.toMap(LessonAttendanceRepository.StatusCount::getStatus,
                        LessonAttendanceRepository.StatusCount::getTotal));
        long present = counts.getOrDefault(AttendanceStatus.PRESENT, 0L);
        long late = counts.getOrDefault(AttendanceStatus.LATE, 0L);
        long absent = counts.getOrDefault(AttendanceStatus.ABSENT, 0L);
        long lessons = present + late + absent;
        Integer percentage = lessons == 0 ? null : (int) Math.round((present + late) * 100.0 / lessons);
        int threshold = organisations.findById(actor.organisationId())
                .map(Organisation::getAttendanceThresholdPct).orElse((short) 80);
        return new AttendanceStatisticsResponse(lessons, present, late, absent, percentage, threshold,
                percentage != null && percentage < threshold);
    }

    private void requireStudentInScope(CurrentUser actor, UUID studentId) {
        AccessScope scope = scopes.scopeFor(actor);
        students.findInScope(studentId, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Student"));
    }
}
