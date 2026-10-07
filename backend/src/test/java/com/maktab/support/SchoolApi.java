package com.maktab.support;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Helpers that set up classes, students and parents through the API, with unique names per test. */
public abstract class SchoolApi extends IntegrationTest {

    protected static String unique(String prefix) {
        return prefix + " " + UUID.randomUUID().toString().substring(0, 8);
    }

    protected MockHttpServletRequestBuilder as(Session session, MockHttpServletRequestBuilder request) {
        return request.header("Authorization", session.bearer()).contentType(MediaType.APPLICATION_JSON);
    }

    protected UUID createLevel(Session admin) throws Exception {
        return idOf(mvc.perform(as(admin, post("/api/curriculum-levels"))
                        .content("{\"name\":\"" + unique("Level") + "\",\"sortOrder\":1}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }

    protected UUID createClass(Session admin) throws Exception {
        UUID levelId = createLevel(admin);
        return idOf(mvc.perform(as(admin, post("/api/classes"))
                        .content("{\"name\":\"" + unique("Class") + "\",\"curriculumLevelId\":\"" + levelId
                                + "\",\"room\":\"Room 1\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }

    protected void assignTeachers(Session admin, UUID classId, UUID... teacherIds) throws Exception {
        StringBuilder ids = new StringBuilder();
        for (UUID id : teacherIds) {
            ids.append(ids.isEmpty() ? "" : ",").append('"').append(id).append('"');
        }
        mvc.perform(as(admin, put("/api/classes/{id}/teachers", classId)).content("{\"teacherIds\":[" + ids + "]}"))
                .andExpect(status().isOk());
    }

    protected UUID createParent(Session admin, String lastName) throws Exception {
        return idOf(mvc.perform(as(admin, post("/api/parents"))
                        .content("{\"firstName\":\"Fatima\",\"lastName\":\"" + lastName
                                + "\",\"phone\":\"+31 6 1234 5678\",\"email\":\"parent@example.com\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }

    /** Creates a student in {@code classId} (may be null) with an optional parent link. */
    protected UUID createStudent(Session admin, String firstName, UUID classId, UUID parentId) throws Exception {
        String classJson = classId == null ? "null" : "\"" + classId + "\"";
        String parentsJson = parentId == null ? "[]"
                : "[{\"parentId\":\"" + parentId + "\",\"relationship\":\"MOTHER\",\"primaryContact\":true}]";
        return idOf(mvc.perform(as(admin, post("/api/students"))
                        .content("{\"firstName\":\"" + firstName + "\",\"lastName\":\"Test\","
                                + "\"dateOfBirth\":\"2017-03-14\",\"gender\":\"FEMALE\",\"joinedOn\":\"2026-09-01\","
                                + "\"classId\":" + classJson + ",\"parents\":" + parentsJson + "}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
    }

    protected static UUID idOf(String json) {
        return UUID.fromString(JsonPath.read(json, "$.id"));
    }
}
