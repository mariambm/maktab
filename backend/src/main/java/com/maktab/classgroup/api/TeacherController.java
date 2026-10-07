package com.maktab.classgroup.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.ClassService;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Lets class managers pick teachers without needing the user administration permission. */
@RestController
@RequestMapping("/api/teachers")
public class TeacherController {

    private final ClassService classService;

    public TeacherController(ClassService classService) {
        this.classService = classService;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('CLASS_MANAGE')")
    public List<TeacherRef> list(@AuthenticationPrincipal CurrentUser currentUser) {
        return classService.teacherOptions(currentUser);
    }
}
