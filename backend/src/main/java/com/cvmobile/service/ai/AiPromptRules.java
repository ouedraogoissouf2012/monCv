package com.cvmobile.service.ai;

/**
 * Constantes de regles injectees dans les prompts IA.
 * Centralise les regles pour garantir la coherence entre les services.
 */
public final class AiPromptRules {

    private AiPromptRules() {}

    public static final String GRAMMAR_RULE =
            "REGLE GRAMMAIRE CRITIQUE: "
            + "Les participes passés doivent TOUJOURS être au SINGULIER MASCULIN. "
            + "CORRECT: Développé, Conçu, Optimisé, Réduit, Déployé, Livré, Implémenté. "
            + "INCORRECT: Développés, Conçus, Optimisés, Résolus, Déployés, Livrés. "
            + "Le sujet implicite est 'je' (singulier). "
            + "Ne JAMAIS utiliser de markdown (pas de ** ni de * ni de #). Texte brut uniquement. ";

    public static final String TITLE_RULE =
            "REGLE TITRE: Le titre du poste doit être COURT et STANDARD. "
            + "Exemples corrects: 'Développeur Full Stack Senior', 'Ingénieur Backend Java', "
            + "'Lead Developer Angular', 'Architecte Logiciel'. "
            + "INCORRECT: 'Ingénieur Développement Full Stack' (mot 'Développement' redondant). "
            + "Maximum 5 mots. Pas de phrase, juste un titre de poste. ";

    public static final String ANTI_CLICHES_RULE =
            "REGLE ANTI-CLICHES: Ne JAMAIS utiliser ces mots ou expressions : "
            + "motivé, déterminé, dynamique, passionné, polyvalent, rigoureux, autonome, "
            + "force de proposition, esprit d'équipe, proactif, réactif, "
            + "approche orientée résultats, expérience avérée, cycles optimisés, "
            + "forte capacité, sens du détail, grande aisance. "
            + "Remplace-les par des FAITS CONCRETS et MESURABLES. ";

    public static final String STYLE_RULE =
            "REGLE DE STYLE NATUREL: "
            + "Ecris dans un francais professionnel francophone, clair pour les recruteurs d'Afrique francophone "
            + "et comprehensible dans un contexte international. "
            + "Evite les tournures trop parisiennes, les anglicismes inutiles et les phrases marketing. "
            + "VARIE les structures de phrases mais garde un style HOMOGENE au sein de chaque experience. "
            + "Choisis UN style par experience et garde-le pour tous les bullets de cette experience. "
            + "Styles possibles: "
            + "- Participe passe singulier : 'Développé 5 applications web en Java/Angular' "
            + "- Contexte + résultat : 'Au sein d'une équipe Agile, livraison de 100% des sprints' "
            + "NE PAS melanger les deux dans la meme experience. "
            + "Cela rend le CV naturel et professionnel. ";

    public static final String QUANTIFICATION_RULE =
            "REGLE CHIFFRES: CONSERVE tous les chiffres que le candidat a fournis. "
            + "Si le candidat a ecrit '5 applications' ou '30%', GARDE ces chiffres. "
            + "Si une description n'a AUCUN chiffre, N'INVENTE aucune metrique, estimation ou placeholder. "
            + "Ameliore alors la precision avec les faits qualitatifs reellement fournis. ";

    public static final String GROUNDING_RULE =
            "REGLE DE FIDELITE PRIORITAIRE: Le contenu du candidat est la seule source de verite. "
            + "Conserve son metier, son secteur, ses responsabilites et son intention. "
            + "Ameliore la formulation et explicite uniquement ce qui est directement deduisible. "
            + "Ne remplace jamais le poste par un autre et n'invente aucune mission, technologie, "
            + "competence, responsabilite, resultat, chiffre, client ou contexte. ";

    public static final String FRANCOPHONE_MARKET_RULE =
            "REGLE MARCHE FRANCOPHONE: "
            + "Valorise les realisations utiles aux PME, startups, ONG, administrations, banques, telecoms, "
            + "commerce, education, sante, logistique et services numeriques. "
            + "Quand le contexte est local, privilegie des resultats concrets: delais reduits, clients servis, "
            + "processus fiabilises, ventes, adoption utilisateur, qualite de service, couts maitrises. "
            + "Ne jamais inventer de diplome, certification, entreprise ou pays. ";

    public static final String PROJECT_RULE =
            "REGLE PROJETS: Pour les projets personnels, ENRICHIS la description. "
            + "Ajoute 3-4 bullet points avec: technologies utilisees, fonctionnalites cles, "
            + "nombre d'utilisateurs si applicable. NE JAMAIS reduire une description de projet. ";

    public static final String SKILL_CATEGORY_RULE =
            "REGLE COMPETENCES: Regroupe les competences par categorie si possible. "
            + "Format: 'Backend: Java, Spring Boot | Frontend: Angular, TypeScript | DevOps: Docker, CI/CD' "
            + "LIMITE a 10 competences maximum. Garde les acronymes intacts (CI/CD, API REST, etc.). ";

    public static final String PROOFREADING_SKILL_RULE =
            "REGLE CORRECTION DES COMPETENCES: Corrige uniquement l'orthographe, les accents et la casse. "
            + "Conserve chaque technologie et chaque terme du libelle original, dans le meme ordre. "
            + "Ne supprime, ne fusionne, ne traduis et ne remplace aucune competence. ";
}
