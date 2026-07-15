package com.cvmobile.service.pdf.style;

import java.awt.Color;

public record PdfTheme(
        Color primary,
        Color text,
        Color muted,
        Color light,
        Color surface,
        float horizontalMargin,
        TitleStyle titleStyle,
        boolean centeredHeader) {

    public enum TitleStyle { BAND, RULE, ACCENT }

    public static PdfTheme moderne() {
        return new PdfTheme(new Color(37, 99, 235), new Color(55, 65, 81),
                new Color(107, 114, 128), new Color(219, 234, 254), Color.WHITE,
                40, TitleStyle.BAND, false);
    }

    public static PdfTheme classique() {
        return new PdfTheme(new Color(17, 24, 39), new Color(55, 65, 81),
                new Color(107, 114, 128), new Color(229, 231, 235), Color.WHITE,
                50, TitleStyle.RULE, true);
    }

    public static PdfTheme minimaliste() {
        return new PdfTheme(new Color(99, 102, 241), new Color(15, 23, 42),
                new Color(71, 85, 105), new Color(203, 213, 225), Color.WHITE,
                0, TitleStyle.ACCENT, false);
    }

    public static PdfTheme creatif() {
        return new PdfTheme(new Color(219, 39, 119), new Color(31, 41, 55),
                new Color(107, 114, 128), new Color(252, 231, 243), new Color(255, 247, 237),
                36, TitleStyle.BAND, false);
    }
}
