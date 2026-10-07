package com.maktab.curriculum.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.domain.CurriculumLevel;
import com.maktab.classgroup.persistence.CurriculumLevelRepository;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.ConflictException;
import com.maktab.common.NotFoundException;
import com.maktab.curriculum.api.CurriculumPeriodRequest;
import com.maktab.curriculum.api.CurriculumPeriodResponse;
import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.api.CurriculumWeekRequest;
import com.maktab.curriculum.api.CurriculumWeekResponse;
import com.maktab.curriculum.api.LessonTopicRequest;
import com.maktab.curriculum.api.LessonTopicResponse;
import com.maktab.curriculum.domain.CurriculumPeriod;
import com.maktab.curriculum.domain.CurriculumWeek;
import com.maktab.curriculum.domain.LessonTopic;
import com.maktab.curriculum.persistence.CurriculumPeriodRepository;
import com.maktab.curriculum.persistence.CurriculumWeekRepository;
import com.maktab.curriculum.persistence.LessonTopicRepository;
import com.maktab.organisation.application.OrganisationCalendar;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Four-week curriculum periods per level, with their weeks and topics. Reading is open to everyone with
 * {@code CURRICULUM_READ} (teachers included); writing needs {@code CURRICULUM_WRITE}.
 */
@Service
public class CurriculumService {

    private static final String ENTITY = "CurriculumPeriod";

    private final CurriculumPeriodRepository periods;
    private final CurriculumWeekRepository weeks;
    private final LessonTopicRepository topics;
    private final CurriculumLevelRepository levels;
    private final OrganisationCalendar calendar;
    private final AuditService audit;

    public CurriculumService(CurriculumPeriodRepository periods, CurriculumWeekRepository weeks,
            LessonTopicRepository topics, CurriculumLevelRepository levels, OrganisationCalendar calendar,
            AuditService audit) {
        this.periods = periods;
        this.weeks = weeks;
        this.topics = topics;
        this.levels = levels;
        this.calendar = calendar;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public List<CurriculumPeriodSummary> list(CurrentUser actor, UUID levelId) {
        List<UUID> levelIds = levelId == null
                ? levels.findByOrganisationIdOrderBySortOrderAscNameAsc(actor.organisationId()).stream()
                        .map(CurriculumLevel::getId).toList()
                : List.of(requireLevel(actor, levelId).getId());
        return levelIds.stream()
                .flatMap(id -> periods.findByCurriculumLevelIdOrderByNumberAsc(id).stream())
                .map(CurriculumPeriodSummary::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public CurriculumPeriodResponse get(CurrentUser actor, UUID id) {
        return toResponse(actor, load(actor, id));
    }

    /** The period of {@code levelId} that contains today, or 404 when no period covers today yet. */
    @Transactional(readOnly = true)
    public CurriculumPeriodResponse current(CurrentUser actor, UUID levelId) {
        CurriculumLevel level = requireLevel(actor, levelId);
        LocalDate today = calendar.today(actor.organisationId());
        return toResponse(actor, periods.findOnDate(level.getId(), today)
                .orElseThrow(() -> new NotFoundException(ENTITY)));
    }

    @Transactional
    public CurriculumPeriodResponse create(CurrentUser actor, CurriculumPeriodRequest request) {
        CurriculumLevel level = requireLevel(actor, request.curriculumLevelId());
        short number = request.number().shortValue();
        if (periods.existsByCurriculumLevelIdAndNumber(level.getId(), number)) {
            throw new ConflictException("This level already has a period with this number");
        }
        CurriculumPeriod period = new CurriculumPeriod(level.getId(), number, request.name().trim(),
                request.startDate());
        requireNoOverlap(level.getId(), period, null);
        periods.save(period);
        replaceWeeks(period, request.weeksOrEmpty());
        CurriculumPeriodResponse response = toResponse(actor, period);
        audit.record(actor, AuditAction.CURRICULUM_PERIOD_CREATED, ENTITY, period.getId(), null, response);
        return response;
    }

    @Transactional
    public CurriculumPeriodResponse update(CurrentUser actor, UUID id, CurriculumPeriodRequest request) {
        CurriculumPeriod period = load(actor, id);
        if (!period.getCurriculumLevelId().equals(request.curriculumLevelId())) {
            throw new BusinessValidationException("curriculumLevelId", "A period cannot move to another level");
        }
        if (period.getNumber() != request.number().shortValue()) {
            throw new BusinessValidationException("number", "A period's number cannot change");
        }
        CurriculumPeriodResponse before = toResponse(actor, period);
        period.update(request.name().trim(), request.startDate());
        requireNoOverlap(period.getCurriculumLevelId(), period, period.getId());
        replaceWeeks(period, request.weeksOrEmpty());
        CurriculumPeriodResponse after = toResponse(actor, period);
        audit.record(actor, AuditAction.CURRICULUM_PERIOD_UPDATED, ENTITY, id, before, after);
        return after;
    }

    /**
     * The period covering {@code date} for a level, used by lessons to offer that week's topics. Empty when the
     * level has no period for that date.
     */
    @Transactional(readOnly = true)
    public Optional<CurriculumPeriod> periodOn(UUID levelId, LocalDate date) {
        return periods.findOnDate(levelId, date);
    }

    /** The topics of the week that {@code date} falls in, in order. */
    @Transactional(readOnly = true)
    public List<LessonTopicResponse> topicsForWeekOf(CurriculumPeriod period, LocalDate date) {
        return period.weekNumberOn(date)
                .flatMap(weekNumber -> weeks.findByCurriculumPeriodIdOrderByWeekNumberAsc(period.getId()).stream()
                        .filter(w -> w.getWeekNumber() == weekNumber)
                        .findFirst())
                .map(week -> topics.findByCurriculumWeekIdInOrderBySortOrderAscTitleAsc(List.of(week.getId())).stream()
                        .map(LessonTopicResponse::from).toList())
                .orElseGet(List::of);
    }

    /** Fails unless every id in {@code topicIds} is a topic of {@code periodId}. */
    @Transactional(readOnly = true)
    public List<LessonTopic> requireTopicsInPeriod(Set<UUID> topicIds, UUID periodId) {
        if (topicIds.isEmpty()) {
            return List.of();
        }
        List<LessonTopic> found = topics.findInPeriod(topicIds, periodId);
        if (found.size() != topicIds.size()) {
            throw new BusinessValidationException("topicIds", "Choose topics from this class's curriculum period");
        }
        return found;
    }

    /** Rewrites the four weeks and their topics; weeks keep their identity so existing lessons stay valid. */
    private void replaceWeeks(CurriculumPeriod period, List<CurriculumWeekRequest> requested) {
        List<CurriculumWeek> existing = weeks.findByCurriculumPeriodIdOrderByWeekNumberAsc(period.getId());
        if (!existing.isEmpty()) {
            topics.deleteByCurriculumWeekIdIn(existing.stream().map(CurriculumWeek::getId).toList());
            topics.flush();
        }
        Map<Integer, CurriculumWeekRequest> byNumber = new java.util.HashMap<>();
        for (CurriculumWeekRequest week : requested) {
            if (byNumber.put(week.weekNumber(), week) != null) {
                throw new BusinessValidationException("weeks", "Week " + week.weekNumber() + " appears twice");
            }
        }
        Map<Short, CurriculumWeek> existingByNumber = existing.stream()
                .collect(Collectors.toMap(CurriculumWeek::getWeekNumber, Function.identity()));
        for (int number = 1; number <= 4; number++) {
            CurriculumWeekRequest requestedWeek = byNumber.get(number);
            boolean review = requestedWeek == null ? number == CurriculumWeek.REVIEW_WEEK : requestedWeek.isReview();
            CurriculumWeek week = existingByNumber.get((short) number);
            if (week == null) {
                week = weeks.save(new CurriculumWeek(period.getId(), number, review));
            } else {
                week.setReview(review);
            }
            if (requestedWeek != null) {
                int order = 0;
                for (LessonTopicRequest topic : requestedWeek.topicsOrEmpty()) {
                    topics.save(new LessonTopic(week.getId(), topic.title().trim(),
                            blankToNull(topic.learningObjective()), order++));
                }
            }
        }
        weeks.flush();
        topics.flush();
    }

    private void requireNoOverlap(UUID levelId, CurriculumPeriod period, UUID excludeId) {
        List<CurriculumPeriod> overlapping =
                periods.findOverlapping(levelId, period.getStartDate(), period.getEndDate(), excludeId);
        if (!overlapping.isEmpty()) {
            throw new BusinessValidationException("startDate",
                    "These four weeks overlap " + overlapping.getFirst().getName());
        }
    }

    private CurriculumPeriod load(CurrentUser actor, UUID id) {
        CurriculumPeriod period = periods.findById(id).orElseThrow(() -> new NotFoundException(ENTITY));
        requireLevel(actor, period.getCurriculumLevelId());
        return period;
    }

    private CurriculumLevel requireLevel(CurrentUser actor, UUID levelId) {
        return levels.findByIdAndOrganisationId(levelId, actor.organisationId())
                .orElseThrow(() -> new NotFoundException("Curriculum level"));
    }

    private CurriculumPeriodResponse toResponse(CurrentUser actor, CurriculumPeriod period) {
        String levelName = levels.findById(period.getCurriculumLevelId()).map(CurriculumLevel::getName).orElse("");
        List<CurriculumWeek> periodWeeks = weeks.findByCurriculumPeriodIdOrderByWeekNumberAsc(period.getId());
        Map<UUID, List<LessonTopicResponse>> topicsByWeek = topics
                .findByCurriculumWeekIdInOrderBySortOrderAscTitleAsc(periodWeeks.stream()
                        .map(CurriculumWeek::getId).toList())
                .stream()
                .collect(Collectors.groupingBy(LessonTopic::getCurriculumWeekId,
                        Collectors.mapping(LessonTopicResponse::from, Collectors.toList())));
        List<CurriculumWeekResponse> weekResponses = periodWeeks.stream()
                .sorted(Comparator.comparing(CurriculumWeek::getWeekNumber))
                .map(w -> new CurriculumWeekResponse(w.getId(), w.getWeekNumber(), w.isReview(),
                        topicsByWeek.getOrDefault(w.getId(), List.of())))
                .toList();
        return CurriculumPeriodResponse.of(period, levelName, weekResponses);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    /** Levels by id, used by callers that render several periods at once. */
    @Transactional(readOnly = true)
    public Map<UUID, CurriculumLevel> levelsById(Set<UUID> ids) {
        return levels.findByIdIn(ids).stream().collect(Collectors.toMap(CurriculumLevel::getId, Function.identity()));
    }
}
