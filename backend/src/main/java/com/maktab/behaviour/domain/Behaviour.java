package com.maktab.behaviour.domain;

/** The behaviours a teacher can observe in a lesson, as the mosque defined them. */
public enum Behaviour {
    GOOD_QURAN_RECITATION(true),
    LEARNED_ISLAMIC_STUDIES(true),
    LEARNED_NAMAZ_AND_DUAS(true),
    LEARNED_NAAT_OR_SPEECH(true),
    LISTENED_TO_TEACHER(true),
    BEEN_HELPFUL(true),
    ORGANISED(true),
    RESPECTFUL(true),
    GOOD_GROUP_WORK(true),
    USING_TIME_EFFECTIVELY(true),
    OFF_TASK(false),
    NOT_LISTENING(false),
    DISTRACTING(false),
    TALKING(false),
    DISORGANISED(false),
    LACK_OF_EFFORT(false),
    WASTING_TIME(false),
    SHOUTING(false),
    WALKING_OR_RUNNING_AROUND(false);

    private final boolean good;

    Behaviour(boolean good) {
        this.good = good;
    }

    public boolean isGood() {
        return good;
    }
}
