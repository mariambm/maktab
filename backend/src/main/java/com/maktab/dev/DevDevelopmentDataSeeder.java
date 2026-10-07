package com.maktab.dev;

import com.maktab.behaviour.domain.Behaviour;
import com.maktab.behaviour.domain.BehaviourRecord;
import com.maktab.behaviour.persistence.BehaviourRecordRepository;
import com.maktab.curriculum.domain.Subject;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.lesson.domain.Lesson;
import com.maktab.lesson.domain.LessonAttendance;
import com.maktab.lesson.persistence.LessonAttendanceRepository;
import com.maktab.lesson.persistence.LessonRepository;
import com.maktab.progress.domain.StudentProgress;
import com.maktab.progress.persistence.StudentProgressRepository;
import com.maktab.uniform.domain.UniformReason;
import com.maktab.uniform.domain.UniformRecord;
import com.maktab.uniform.domain.UniformStatus;
import com.maktab.uniform.persistence.UniformRecordRepository;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
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
 * Development-only progress scores, behaviour and uniform observations for the seeded lessons, so the student
 * profile has history to show. Runs only with the {@code dev} profile and only when no progress exists yet.
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

    public DevDevelopmentDataSeeder(LessonRepository lessons, LessonAttendanceRepository attendance,
            StudentProgressRepository progress, BehaviourRecordRepository behaviour,
            UniformRecordRepository uniform) {
        this.lessons = lessons;
        this.attendance = attendance;
        this.progress = progress;
        this.behaviour = behaviour;
        this.uniform = uniform;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
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
}
