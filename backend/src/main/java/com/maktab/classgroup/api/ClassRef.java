package com.maktab.classgroup.api;

import java.util.UUID;

/** A class as it appears inside other resources: id and name only. */
public record ClassRef(UUID id, String name) {
}
