package com.maktab.config;

import static org.assertj.core.api.Assertions.assertThat;

import com.maktab.auth.api.AuthController;
import com.maktab.support.IntegrationTest;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

/**
 * Guards against a new endpoint shipping without an authorisation rule: every Maktab controller method outside the
 * public login endpoints must carry {@code @PreAuthorize}, on the method or its class.
 */
class EndpointSecurityCoverageTest extends IntegrationTest {

    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    RequestMappingHandlerMapping handlerMapping;

    @Test
    void everyEndpointDeclaresAnAuthorisationRule() {
        List<String> unprotected = handlerMapping.getHandlerMethods().values().stream()
                .filter(handler -> handler.getBeanType().getPackageName().startsWith("com.maktab"))
                .filter(handler -> handler.getBeanType() != AuthController.class)
                .filter(handler -> !AnnotatedElementUtils.hasAnnotation(handler.getMethod(), PreAuthorize.class)
                        && !AnnotatedElementUtils.hasAnnotation(handler.getBeanType(), PreAuthorize.class))
                .map(handler -> handler.getBeanType().getSimpleName() + "#" + handler.getMethod().getName())
                .toList();

        assertThat(unprotected).isEmpty();
        assertThat(handlerMapping.getHandlerMethods()).isNotEmpty();
    }
}
