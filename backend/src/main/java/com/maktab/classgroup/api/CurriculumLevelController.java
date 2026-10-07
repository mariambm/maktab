package com.maktab.classgroup.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.ClassService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/curriculum-levels")
public class CurriculumLevelController {

    private final ClassService classService;

    public CurriculumLevelController(ClassService classService) {
        this.classService = classService;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public List<CurriculumLevelResponse> list(@AuthenticationPrincipal CurrentUser currentUser) {
        return classService.levels(currentUser);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('CLASS_MANAGE')")
    public CurriculumLevelResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody CreateCurriculumLevelRequest request) {
        return classService.createLevel(currentUser, request);
    }
}
