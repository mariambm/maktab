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
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.organisation.domain.Organisation;
import com.maktab.parent.domain.ParentGuardian;
import com.maktab.parent.persistence.ParentGuardianRepository;
import com.maktab.student.domain.Gender;
import com.maktab.student.domain.ParentRelationship;
import com.maktab.student.domain.Student;
import com.maktab.student.domain.StudentParent;
import com.maktab.student.persistence.StudentParentRepository;
import com.maktab.student.persistence.StudentRepository;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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
 * Development-only fake school: 3 curriculum levels, 6 classes with schedules and teachers, 30 students and 20
 * parents (8 of them with two or more children), plus a few students who moved class so history is visible. Runs
 * only with the {@code dev} profile and only when there are no students yet. All names are invented.
 */
@Component
@Profile("dev")
@Order(2)
public class DevSchoolDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevSchoolDataSeeder.class);
    private static final java.util.UUID ORG = Organisation.DEFAULT_ID;

    private record SeedClass(String name, int level, String room, String teacherEmail, DayOfWeek day,
            LocalTime start, LocalTime end) {
    }

    private static final List<SeedClass> CLASSES = List.of(
            new SeedClass("Saturday Beginners A", 0, "Room 1", "teacher1@maktab.local", DayOfWeek.SATURDAY,
                    LocalTime.of(10, 0), LocalTime.of(12, 0)),
            new SeedClass("Saturday Qaida B", 1, "Room 2", "teacher2@maktab.local", DayOfWeek.SATURDAY,
                    LocalTime.of(10, 0), LocalTime.of(12, 0)),
            new SeedClass("Saturday Quran C", 2, "Room 3", "teacher3@maktab.local", DayOfWeek.SATURDAY,
                    LocalTime.of(13, 0), LocalTime.of(15, 0)),
            new SeedClass("Sunday Beginners D", 0, "Room 1", "teacher4@maktab.local", DayOfWeek.SUNDAY,
                    LocalTime.of(10, 0), LocalTime.of(12, 0)),
            new SeedClass("Sunday Qaida E", 1, "Room 2", "teacher1@maktab.local", DayOfWeek.SUNDAY,
                    LocalTime.of(10, 0), LocalTime.of(12, 0)),
            new SeedClass("Wednesday Quran F", 2, "Room 3", "teacher2@maktab.local", DayOfWeek.WEDNESDAY,
                    LocalTime.of(17, 0), LocalTime.of(18, 30)));

    private static final String[] FAMILY_NAMES = {
        "Amrani", "Bakkali", "Celik", "Demir", "El Idrissi", "Farouk", "Ghazi", "Haddad", "Iqbal", "Jaber",
        "Karim", "Laaroussi", "Mansour", "Naciri", "Osman", "Qureshi", "Rashid", "Saleh", "Tahiri", "Uddin"};
    private static final String[] MOTHER_NAMES = {
        "Fatima", "Zainab", "Hafsa", "Samira", "Naima", "Leila", "Rania", "Salma", "Yasmin", "Nadia"};
    private static final String[] FATHER_NAMES = {
        "Ahmed", "Hamza", "Karim", "Mustafa", "Rachid", "Tarik", "Walid", "Younes", "Hassan", "Idris"};
    private static final String[] GIRL_NAMES = {
        "Amina", "Sara", "Noor", "Maryam", "Huda", "Imane", "Layla", "Safiya", "Ruqayya", "Asma", "Hiba",
        "Iman", "Sumaya", "Aya", "Khadija"};
    private static final String[] BOY_NAMES = {
        "Adam", "Ayoub", "Bilal", "Daoud", "Elias", "Hamid", "Ilyas", "Jamal", "Khalid", "Musa", "Nabil",
        "Rayan", "Sami", "Yahya", "Zakaria"};

    /** Children per family; 8 of the 20 families have two or more. Sums to 30. */
    private static final int[] CHILDREN_PER_FAMILY = {3, 2, 2, 2, 2, 2, 2, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1};

    private final UserRepository users;
    private final CurriculumLevelRepository levels;
    private final ClassGroupRepository classes;
    private final ClassScheduleRepository schedules;
    private final ClassTeacherRepository classTeachers;
    private final ClassEnrollmentRepository enrollments;
    private final StudentRepository students;
    private final ParentGuardianRepository parents;
    private final StudentParentRepository links;
    private final OrganisationCalendar calendar;

    public DevSchoolDataSeeder(UserRepository users, CurriculumLevelRepository levels,
            ClassGroupRepository classes, ClassScheduleRepository schedules, ClassTeacherRepository classTeachers,
            ClassEnrollmentRepository enrollments, StudentRepository students, ParentGuardianRepository parents,
            StudentParentRepository links, OrganisationCalendar calendar) {
        this.users = users;
        this.levels = levels;
        this.classes = classes;
        this.schedules = schedules;
        this.classTeachers = classTeachers;
        this.enrollments = enrollments;
        this.students = students;
        this.parents = parents;
        this.links = links;
        this.calendar = calendar;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (students.count() > 0 || levels.count() > 0) {
            return;
        }
        LocalDate today = calendar.today(ORG);
        LocalDate termStart = today.minusMonths(3);
        Map<String, User> usersByEmail = users.findAll().stream()
                .collect(Collectors.toMap(User::getEmail, Function.identity()));

        List<CurriculumLevel> levelList = levels.saveAll(List.of(
                new CurriculumLevel(ORG, "Beginners", (short) 1),
                new CurriculumLevel(ORG, "Qaida", (short) 2),
                new CurriculumLevel(ORG, "Quran", (short) 3)));

        List<ClassGroup> classList = new ArrayList<>();
        for (SeedClass seed : CLASSES) {
            ClassGroup classGroup = classes.save(new ClassGroup(ORG, levelList.get(seed.level()).getId(),
                    seed.name(), seed.room()));
            classList.add(classGroup);
            schedules.save(new ClassSchedule(classGroup.getId(), seed.day(), seed.start(), seed.end()));
            User teacher = usersByEmail.get(seed.teacherEmail());
            if (teacher != null) {
                classTeachers.save(new ClassTeacher(classGroup.getId(), teacher.getId(), termStart));
            }
        }

        int studentIndex = 0;
        for (int family = 0; family < FAMILY_NAMES.length; family++) {
            String lastName = FAMILY_NAMES[family];
            ParentGuardian parent = family % 2 == 0
                    ? new ParentGuardian(ORG, MOTHER_NAMES[family / 2], lastName, phone(family), null)
                    : new ParentGuardian(ORG, FATHER_NAMES[family / 2], lastName, phone(family),
                            email(FATHER_NAMES[family / 2], lastName));
            parents.save(parent);
            ParentRelationship relationship = family % 2 == 0 ? ParentRelationship.MOTHER : ParentRelationship.FATHER;
            for (int child = 0; child < CHILDREN_PER_FAMILY[family]; child++, studentIndex++) {
                boolean girl = studentIndex % 2 == 0;
                String firstName = girl ? GIRL_NAMES[studentIndex / 2] : BOY_NAMES[studentIndex / 2];
                LocalDate birth = today.minusYears(6 + (studentIndex % 8)).minusDays(studentIndex * 11L);
                Student student = students.save(new Student(ORG, firstName, lastName, birth,
                        girl ? Gender.FEMALE : Gender.MALE, termStart, null));
                students.flush();
                links.save(new StudentParent(student.getId(), parent.getId(), relationship, true));
                ClassGroup classGroup = classList.get(studentIndex % classList.size());
                if (studentIndex % 10 == 3) {
                    // A few students moved class mid-term, so the class history has something to show.
                    ClassGroup previous = classList.get((studentIndex + 1) % classList.size());
                    ClassEnrollment old = new ClassEnrollment(student.getId(), previous.getId(), termStart);
                    old.end(today.minusWeeks(4));
                    enrollments.saveAndFlush(old);
                    enrollments.save(new ClassEnrollment(student.getId(), classGroup.getId(), today.minusWeeks(4)));
                } else {
                    enrollments.save(new ClassEnrollment(student.getId(), classGroup.getId(), termStart));
                }
            }
        }
        log.info("Seeded {} levels, {} classes, {} students and {} parents (fake data)", levelList.size(),
                classList.size(), studentIndex, FAMILY_NAMES.length);
    }

    private static String phone(int index) {
        return String.format("+31 6 %04d %04d", 1000 + index * 37, 2000 + index * 53);
    }

    private static String email(String firstName, String lastName) {
        return (firstName + "." + lastName.replace(" ", "")).toLowerCase() + "@example.com";
    }
}
