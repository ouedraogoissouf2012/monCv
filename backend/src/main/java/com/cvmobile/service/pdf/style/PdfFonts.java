package com.cvmobile.service.pdf.style;

import com.lowagie.text.Font;

public final class PdfFonts {

    private final PdfTheme theme;

    public PdfFonts(PdfTheme theme) {
        this.theme = theme;
    }

    public Font name() { return font(24, Font.BOLD, theme.primary()); }
    public Font job() { return font(13, Font.NORMAL, theme.muted()); }
    public Font section() { return font(11, Font.BOLD, theme.primary()); }
    public Font sectionOnPrimary() { return font(11, Font.BOLD, java.awt.Color.WHITE); }
    public Font item() { return font(11, Font.BOLD, theme.text()); }
    public Font sub() { return font(9, Font.ITALIC, theme.muted()); }
    public Font body() { return font(10, Font.NORMAL, theme.text()); }
    public Font contact() { return font(9, Font.NORMAL, theme.muted()); }

    private Font font(float size, int style, java.awt.Color color) {
        return new Font(Font.HELVETICA, size, style, color);
    }
}
