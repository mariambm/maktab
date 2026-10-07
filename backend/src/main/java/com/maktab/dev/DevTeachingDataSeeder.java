package com.maktab.dev;

import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.domain.ClassSchedule;
import com.maktab.classgroup.domain.ClassTeacher;
import com.maktab.classgroup.domain.CurriculumLevel;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.classgroup.persistence.ClassScheduleRepository;
import com.maktab.classgroup.persistence.ClassTeacherRepository;
import com.maktab.classgroup.persistence.CurriculumLevelRepository;
import com.maktab.curriculum.domain.CurriculumPeriod;
import com.maktab.curriculum.domain.CurriculumWeek;
import com.maktab.curriculum.domain.LessonTopic;
import com.maktab.curriculum.domain.Subject;
import com.maktab.curriculum.persistence.CurriculumPeriodRepository;
import com.maktab.curriculum.persistence.CurriculumWeekRepository;
import com.maktab.curriculum.persistence.LessonTopicRepository;
import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.lesson.domain.Lesson;
import com.maktab.lesson.domain.LessonAttendance;
import com.maktab.lesson.domain.LessonStatus;
import com.maktab.lesson.domain.LessonTopicCovered;
import com.maktab.lesson.persistence.LessonAttendanceRepository;
import com.maktab.lesson.persistence.LessonRepository;
import com.maktab.lesson.persistence.LessonTopicCoveredRepository;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.organisation.domain.Organisation;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
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
 * Development-only teaching data on top of the fake school: a four-week curriculum period per level with topics,
 * and the past eight weeks of lessons with attendance. Runs only with the {@code dev} profile and only when there
 * are no curriculum periods yet.
 */
@Component
@Profile("dev")
@Order(3)
public class DevTeachingDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevTeachingDataSeeder.class);
    private static final UUID ORG = Organisation.DEFAULT_ID;

    /** Topics per level, four weeks each; the fourth week is review. */
    /** A second topic each week, the same for every level: (subject, title, objective). */
    private static final String[][] SHARED_TOPICS = {
        {"NAMAZ_AND_DUAS", "Wudu step by step", "Perform wudu in the right order"},
        {"ISLAMIC_STUDIES", "The five pillars of Islam", "Name and explain the five pillars"},
        {"NAATS_AND_SPEECHES", "A short naat", "Recite a short naat with confidence"},
        {"NAMAZ_AND_DUAS", "Duas before and after eating", "Recite both duas from memory"}};

    private static final Map<String, String[][]> TOPICS = Map.of(
            "Beginners", new String[][] {
                    {"The Arabic alphabet: alif to jim", "Recognise and pronounce the first five letters"},
                    {"Letters dal to zay", "Read the letters in isolation"},
                    {"Short vowels: fatha, kasra, damma", "Read simple two-letter combinations"},
                    {"Review of weeks 1 to 3", "Read a short line of letters with vowels"}},
            "Qaida", new String[][] {
                    {"Joining letters at the start of a word", "Read three-letter words fluently"},
                    {"Sukoon and its sound", "Apply sukoon in short words"},
                    {"Shadda: doubling a letter", "Read words containing shadda"},
                    {"Review and reading assessment", "Read a short passage from the Qaida"}},
            "Quran", new String[][] {
                    {"Surah Al-Fatiha: verses 1 to 4", "Recite with correct pronunciation"},
                    {"Surah Al-Fatiha: verses 5 to 7", "Complete the surah from memory"},
                    {"Rules of noon saakin", "Recognise idgham and ikhfa in practice"},
                    {"Review and recitation", "Recite the surah applying the rules learned"}});

    private final CurriculumLevelRepository levels;
    private final CurriculumPeriodRepository periods;
    private final CurriculumWeekRepository weeks;
    private final LessonTopicRepository topics;
    private final ClassGroupRepository classes;
    private final ClassScheduleRepository schedules;
    private final ClassTeacherRepository classTeachers;
    private final ClassEnrollmentRepository enrollments;
    private final LessonRepository lessons;
    private final LessonAttendanceRepository attendance;
    private final LessonTopicCoveredRepository coveredTopics;
    private final OrganisationCalendar calendar;

    public DevTeachingDataSeeder(CurriculumLevelRepository levels, CurriculumPeriodRepository periods,
            CurriculumWeekRepository weeks, LessonTopicRepository topics, ClassGroupRepository classes,
            ClassScheduleRepository schedules, ClassTeacherRepository classTeachers,
            ClassEnrollmentRepository enrollments, LessonRepository lessons, LessonAttendanceRepository attendance,
            LessonTopicCoveredRepository coveredTopics, OrganisationCalendar calendar) {
        this.levels = levels;
        this.periods = periods;
        this.weeks = weeks;
        this.topics = topics;
        this.classes = classes;
        this.schedules = schedules;
        this.classTeachers = classTeachers;
        this.enrollments = enrollments;
        this.lessons = lessons;
        this.attendance = attendance;
        this.coveredTopics = coveredTopics;
        this.calendar = calendar;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (periods.count() > 0) {
            return;
        }
        List<CurriculumLevel> levelList = levels.findByOrganisationIdOrderBySortOrderAscNameAsc(ORG);
        if (levelList.isEmpty()) {
            return;
        }
        LocalDate today = calendar.today(ORG);
        // The current period starts on the Monday two weeks ago, so today falls in week 3.
        LocalDate periodStart = today.minusWeeks(2).with(java.time.DayOfWeek.MONDAY);

        Map<UUID, List<LessonTopic>> topicsByLevel = new java.util.HashMap<>();
        for (CurriculumLevel level : levelList) {
            String[][] weekTopics = TOPICS.getOrDefault(level.getName(), TOPICS.get("Beginners"));
            // Beginners learn the Arabic letters; Qaida and Quran are recitation.
            Subject subject = "Beginners".equals(level.getName()) ? Subject.ARABIC : Subject.QURAN_RECITATION;
            CurriculumPeriod previous = periods.save(
                    new CurriculumPeriod(level.getId(), 1, "Period 1", periodStart.minusDays(28)));
            addWeeks(previous, subject, weekTopics, new ArrayList<>());
            CurriculumPeriod current = periods.save(new CurriculumPeriod(level.getId(), 2, "Period 2", periodStart));
            List<LessonTopic> saved = new ArrayList<>();
            addWeeks(current, subject, weekTopics, saved);
            topicsByLevel.put(level.getId(), saved);
        }

        Map<UUID, List<UUID>> rosters = enrollments.findAll().stream()
                .filter(ClassEnrollment::isOpen)
                .collect(Collectors.groupingBy(ClassEnrollment::getClassGroupId,
                        Collectors.mapping(ClassEnrollment::getStudentId, Collectors.toList())));
        Map<UUID, UUID> teacherByClass = classTeachers.findAll().stream()
                .filter(assignment -> assignment.getEndDate() == null)
                .collect(Collectors.toMap(ClassTeacher::getClassGroupId, ClassTeacher::getTeacherUserId,
                        (first, second) -> first));

        int lessonCount = 0;
        int attendanceCount = 0;
        for (ClassGroup classGroup : classes.findByOrganisationIdAndActiveTrue(ORG)) {
            List<UUID> roster = rosters.getOrDefault(classGroup.getId(), List.of());
            UUID teacher = teacherByClass.get(classGroup.getId());
            if (roster.isEmpty() || teacher == null) {
                continue;
            }
            List<LessonTopic> levelTopics = topicsByLevel.getOrDefault(classGroup.getCurriculumLevelId(), List.of());
            for (ClassSchedule slot : schedules.findByClassGroupIdInOrderByWeekdayAscStartTimeAsc(
                    List.of(classGroup.getId()))) {
                // The past eight occurrences of this weekly slot, today's lesson left for the teacher to open.
                for (int week = 8; week >= 1; week--) {
                    LocalDate date = today.with(java.time.temporal.TemporalAdjusters.previousOrSame(slot.getWeekday()))
                            .minusWeeks(week);
                    Lesson lesson = lessons.save(new Lesson(classGroup.getId(), slot.getId(), date,
                            slot.getStartTime(), slot.getEndTime(), teacher));
                    lesson.update(slot.getEndTime(), "Revision of the previous week, then the new topic.",
                            LessonStatus.COMPLETED, teacher);
                    lessonCount++;
                    if (!levelTopics.isEmpty()) {
                        coveredTopics.save(new LessonTopicCovered(lesson.getId(),
                                levelTopics.get(week % levelTopics.size()).getId()));
                    }
                    for (int i = 0; i < roster.size(); i++) {
                        LessonAttendance record = new LessonAttendance(lesson.getId(), roster.get(i), teacher);
                        int pattern = (i + week) % 10;
                        if (pattern == 0) {
                            record.record(AttendanceStatus.ABSENT, null, AbsenceReason.SICK, null, teacher);
                        } else if (pattern == 1) {
                            record.record(AttendanceStatus.LATE, 5 + (i % 3) * 5, null, null, teacher);
                        } else {
                            record.record(AttendanceStatus.PRESENT, null, null, null, teacher);
                        }
                        attendance.save(record);
                        attendanceCount++;
                    }
                }
            }
        }
        log.info("Seeded curriculum periods, {} lessons and {} attendance records (fake data)", lessonCount,
                attendanceCount);
    }

    private void addWeeks(CurriculumPeriod period, Subject subject, String[][] weekTopics,
            List<LessonTopic> collect) {
        for (int number = 1; number <= 4; number++) {
            CurriculumWeek week = weeks.save(
                    new CurriculumWeek(period.getId(), number, number == CurriculumWeek.REVIEW_WEEK));
            String[] topic = weekTopics[number - 1];
            collect.add(topics.save(new LessonTopic(week.getId(), subject, topic[0], topic[1], 0)));
            String[] shared = SHARED_TOPICS[number - 1];
            collect.add(topics.save(new LessonTopic(week.getId(), Subject.valueOf(shared[0]), shared[1], shared[2],
                    1)));
        }
    }
}
