package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class JobMatchScorerTest {

    private final JobMatchScorer scorer = new JobMatchScorer(
            new JobMatchTextAnalyzer(),
            new JobMatchProperties(50, 14, 6, 5, 5, 100, 1800));

    @Test
    void ratioScore_totalNul_retourneValeurNeutre() {
        assertThat(scorer.ratioScore(0, 0)).isEqualTo(70);
    }

    @Test
    void ratioScore_estProportionnelAuMaxScore() {
        assertThat(scorer.ratioScore(3, 3)).isEqualTo(100);
        assertThat(scorer.ratioScore(1, 4)).isEqualTo(25);
    }

    @Test
    void buildCategory_clampeLeScoreEtDedupliqueLesPreuves() {
        JobMatchResponse.CategoryScore category = scorer.buildCategory(
                "keywords", "Mots-clés", 150, "Résumé",
                List.of("java", "", "java", "spring"));

        assertThat(category.getScore()).isEqualTo(100); // borne a maxScore
        assertThat(category.getEvidence()).containsExactly("java", "spring"); // vide retire, distinct
    }
}
