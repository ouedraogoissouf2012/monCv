package com.cvmobile.dto;

public final class CvValidationLimits {
    public static final int MAX_SECTION_ITEMS = 50;
    public static final int MAX_SKILLS = 100;
    public static final int MAX_TEMPLATE_LENGTH = 50;
    public static final int MAX_SHORT_TEXT_LENGTH = 100;
    public static final int MAX_MEDIUM_TEXT_LENGTH = 200;
    public static final int MAX_EMAIL_LENGTH = 254;
    public static final int MAX_PHONE_LENGTH = 20;
    public static final int MAX_POSTAL_CODE_LENGTH = 32;
    public static final int MAX_URL_LENGTH = 500;
    public static final int MAX_LONG_TEXT_LENGTH = 10_000;

    private CvValidationLimits() {
    }
}
