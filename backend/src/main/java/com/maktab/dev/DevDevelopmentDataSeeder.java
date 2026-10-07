package com.maktab.dev;

import com.maktab.behaviour.domain.Behaviour;
import com.maktab.behaviour.domain.BehaviourRecord;
import com.maktab.behaviour.persistence.BehaviourRecordRepository;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.curriculum.application.CurriculumService;
import com.maktab.curriculum.domain.CurriculumPeriod;
import com.maktab.curriculum.domain.Subject;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.lesson.domain.Lesson;
import com.maktab.lesson.domain.LessonAttendance;
import com.maktab.lesson.persistence.LessonAttendanceRepository;
import com.maktab.lesson.persistence.LessonRepository;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.organisation.domain.Organisation;
import com.maktab.progress.domain.StudentProgress;
import com.maktab.progress.domain.StudentTarget;
import com.maktab.progress.persistence.StudentProgressRepository;
import com.maktab.progress.persistence.StudentTargetRepository;
import com.maktab.uniform.domain.UniformReason;
import com.maktab.uniform.domain.UniformRecord;
import com.maktab.uniform.domain.UniformStatus;
import com.maktab.uniform.persistence.UniformRecordRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Development-only progress scores, behaviour and uniform observations for the seeded lessons, and targets for the
 * current period, so the student profile and the Progress screen have something to show. Runs only with the
 * {@code dev} profile, and each part only when nothing of its kind exists yet.
 */
@Component
@Profile("dev")
@Order(4)
public class DevDevelopmentDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevDevelopmentDataSeeder.class);
    private static final BigDecimal[] SCORES = {new BigDecimal("3.5"), new BigDecimal("4.0"),
        new BigDecimal("4.5"), new BigDecimal("3.0"), new BigDecimal("5.0"), new BigDecimal("4.0")};

    private final LessonRepository lessons;
    private final LessonAttendanceRepository attendance;
    private final StudentProgressRepository progress;
    private final BehaviourRecordRepository behaviour;
    private final UniformRecordRepository uniform;
    private final StudentTargetRepository targets;
    private final ClassEnrollmentRepository enrollments;
    private final ClassGroupRepository classes;
    private final CurriculumService curriculum;
    private final OrganisationCalendar calendar;

    public DevDevelopmentDataSeeder(LessonRepository lessons, LessonAttendanceRepository attendance,
            StudentProgressRepository progress, BehaviourRecordRepository behaviour,
            UniformRecordRepository uniform, StudentTargetRepository targets, ClassEnrollmentRepository enrollments,
            ClassGroupRepository classes, CurriculumService curriculum, OrganisationCalendar calendar) {
        this.targets = targets;
        this.enrollments = enrollments;
        this.classes = classes;
        this.curriculum = curriculum;
        this.calendar = calendar;
        this.lessons = lessons;
        this.attendance = attendance;
        this.progress = progress;
        this.behaviour = behaviour;
        this.uniform = uniform;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (targets.count() == 0) {
            seedTargets();
        }
        if (progress.count() > 0) {
            return;
        }
        Map<UUID, Lesson> lessonById = lessons.findAll().stream()
                .collect(Collectors.toMap(Lesson::getId, Function.identity()));
        List<LessonAttendance> present = attendance.findAll().stream()
                .filter(a -> a.getStatus() != AttendanceStatus.ABSENT && lessonById.containsKey(a.getLessonId()))
                .toList();
        int scores = 0;
        int observations = 0;
        for (int i = 0; i < present.size(); i++) {
            LessonAttendance seen = present.get(i);
            UUID teacher = lessonById.get(seen.getLessonId()).getTeacherUserId();
            StudentProgress score = new StudentProgress(seen.getLessonId(), seen.getStudentId(),
                    Subject.QURAN_RECITATION);
            score.record(SCORES[(i * 7) % SCORES.length], null, teacher);
            progress.save(score);
            scores++;
            if (i % 5 == 0) {
                BehaviourRecord record = new BehaviourRecord(seen.getLessonId(), seen.getStudentId());
                record.record(i % 15 == 0 ? Set.of(Behaviour.TALKING, Behaviour.NOT_LISTENING)
                        : Set.of(Behaviour.LISTENED_TO_TEACHER, Behaviour.RESPECTFUL), null, teacher);
                behaviour.save(record);
                observations++;
            }
            if (i % 11 == 0) {
                UniformRecord record = new UniformRecord(seen.getLessonId(), seen.getStudentId());
                record.record(UniformStatus.PARTIALLY_IN_ORDER, UniformReason.SHIRT_NOT_ACCORDING_TO_UNIFORM, null,
                        teacher);
                uniform.save(record);
                observations++;
            }
        }
        log.info("Seeded {} progress scores and {} observations (fake data)", scores, observations);
    }

    /** A target in the current period for every other student, so the Progress screen has something to show. */
    private void seedTargets() {
        LocalDate today = calendar.today(Organisation.DEFAULT_ID);
        Map<UUID, ClassGroup> classById = classes.findAll().stream()
                .collect(Collectors.toMap(ClassGroup::getId, Function.identity()));
        UUID author = lessons.findAll().stream().map(Lesson::getTeacherUserId).findFirst().orElse(null);
        if (author == null) {
            return;
        }
        int count = 0;
        List<ClassEnrollment> open = enrollments.findAll().stream().filter(ClassEnrollment::isOpen).toList();
        for (int i = 0; i < open.size(); i += 2) {
            ClassEnrollment enrollment = open.get(i);
            ClassGroup classGroup = classById.get(enrollment.getClassGroupId());
            Optional<CurriculumPeriod> period = curriculum.periodOn(classGroup.getCurriculumLevelId(), today);
            if (period.isEmpty()) {
                continue;
            }
            StudentTarget target = new StudentTarget(enrollment.getStudentId(), period.get().getId(), author);
            target.update(Subject.QURAN_RECITATION, "Recite this period's surah fluently", 85, 60 + (i % 4) * 5,
                    new BigDecimal(i % 3 == 0 ? "3.5" : "4.0"), "Good effort; practise at home every day.", author);
            targets.save(target);
            count++;
        }
        log.info("Seeded {} targets (fake data)", count);
    }
}
