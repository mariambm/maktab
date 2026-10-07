package com.maktab.common;

import java.util.Locale;

public final class SearchTerms {

    private SearchTerms() {
    }

    /**
     * A lower-case {@code %term%} pattern for {@code like ... escape '\'}, with the user's own wildcards escaped,
     * or {@code null} when there is nothing to search for.
     */
    public static String containsPattern(String search) {
        if (search == null || search.isBlank()) {
            return null;
        }
        String escaped = search.trim().toLowerCase(Locale.ROOT)
                .replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
        return "%" + escaped + "%";
    }
}
