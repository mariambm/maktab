package com.maktab.common;

import java.util.Set;
import java.util.UUID;

/**
 * Which classes' data the caller may see. ADMIN and ADMINISTRATOR see every class; a teacher sees only the classes
 * they are currently assigned to. Repository queries take the scope as parameters so out-of-scope rows are filtered
 * in SQL and simply not found (404), never loaded and then rejected.
 */
public record AccessScope(boolean allClasses, Set<UUID> classIds) {

    /** Never matches a real class; keeps {@code in (:classIds)} valid when a teacher has no classes. */
    private static final UUID NO_CLASS = new UUID(0, 0);

    public static AccessScope everything() {
        return new AccessScope(true, Set.of());
    }

    public static AccessScope classes(Set<UUID> classIds) {
        return new AccessScope(false, Set.copyOf(classIds));
    }

    public boolean includes(UUID classId) {
        return allClasses || classIds.contains(classId);
    }

    /** The class ids to bind in a query; never empty. Ignored by queries when {@link #allClasses()} is true. */
    public Set<UUID> queryClassIds() {
        return classIds.isEmpty() ? Set.of(NO_CLASS) : classIds;
    }
}
