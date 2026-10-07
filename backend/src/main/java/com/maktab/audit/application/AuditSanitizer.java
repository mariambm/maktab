package com.maktab.audit.application;

import java.util.Iterator;
import java.util.Locale;
import java.util.Set;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * Removes secrets from audit snapshots. Snapshots should already be DTOs without secrets; this is the safety net.
 */
final class AuditSanitizer {

    private static final Set<String> DENIED = Set.of(
            "password", "passwordhash", "newpassword", "currentpassword", "temporarypassword",
            "token", "accesstoken", "refreshtoken", "secret");

    private AuditSanitizer() {
    }

    static JsonNode sanitize(JsonNode node) {
        if (node == null) {
            return null;
        }
        if (node.isObject()) {
            ObjectNode object = (ObjectNode) node;
            Iterator<String> names = object.propertyNames().iterator();
            while (names.hasNext()) {
                String name = names.next();
                if (DENIED.contains(name.toLowerCase(Locale.ROOT))) {
                    names.remove();
                } else {
                    sanitize(object.get(name));
                }
            }
        } else if (node.isArray()) {
            node.forEach(AuditSanitizer::sanitize);
        }
        return node;
    }
}
