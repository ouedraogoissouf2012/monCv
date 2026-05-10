# Regles du projet MonCV

> **Charte d'ingenierie complete** : `docs/ENGINEERING_CHARTER.md` — a respecter a la lettre.
> Ce fichier ne contient que le condense critique charge automatiquement.

## Le mantra (non negociable)

> Code pret a etre audite demain. Code que 100 000 utilisateurs vont utiliser dans 10 ans.
> On est paye pour la fiabilite, pas pour la vitesse. En cas de doute : propre toujours.

## Hierarchie des priorites (rang superieur l'emporte)

1. Securite > 2. Correction > 3. Lisibilite > 4. Robustesse > 5. Maintenabilite > 6. Performance > 7. Velocite

## Workflow obligatoire pour toute modification non-triviale

### Phase 1 — Analyse (avant tout code)

Repondre dans la PR ou un message :
- **Objectif** (1 phrase)
- **Contraintes** (securite / perf / metier / deadline)
- **Risques** (ce qui peut mal tourner)
- **Strategie retenue** (alternative ecartees + pourquoi)

Si la demande est ambigue : reformuler avant de coder.

### Phase 2 — Workflow multi-agent (revue interne 6 perspectives)

Pour toute PR non-triviale, 6 perspectives doivent passer avant merge :

1. **Planificateur** — "On resout le bon probleme ?"
2. **Codeur** — "Un junior comprend en 5 min ?"
3. **Testeur** — coverage >= 80% sur nouveau code, tests utiles
4. **Securite** — OWASP, secrets, validation entrees, logs (veto absolu)
5. **Architecte** — couches, dependances, separation responsabilites
6. **SOLID/DRY** — god classes, duplication, magic values

Si l'un des 6 trouve un probleme bloquant : on ne merge pas.

### Phase 3 — Verification avant claim (regle d'or)

Ne jamais affirmer "fait", "teste", "verifie", "passe", "fonctionne" sans avoir :
1. Lance la commande qui le prouve
2. Vu sa sortie
3. Cite l'evidence

Si tu n'as pas l'evidence : ecrire "a verifier" ou "non verifie". Jamais de bluff.

## Anti-patterns interdits (avec exemples voir `ENGINEERING_CHARTER.md` section 5)

- `catch (Exception)` silencieux qui retourne un fallback
- Magic numbers > 1 dans la logique metier (sauf 0/1/-1)
- `Color(0xFF...)` hors `app_theme.dart` (utiliser `Theme.of(context).colorScheme.X` ou `AppColors.X`)
- Singleton manuel `static final _instance` quand DI dispo
- Strings UI hardcodees (utiliser `AppLocalizations`)
- Secrets en dur dans le code (clefs API, mots de passe, JWT)
- `ex.getMessage()` brut renvoye au client (information disclosure)
- TODO/FIXME sans issue tracker associee
- Tests triviaux : `assertNotNull(x)` seul, `expect(x, isNotNull)` seul

## Critères production-grade — checklist par PR

Voir `docs/ENGINEERING_CHARTER.md` section 4 pour la checklist complete (architecture, gestion d'erreurs, validation, securite, logs, tests, perf, doc, cleanup).

Resume :
- Aucun fichier > 300 lignes (sauf justification ecrite)
- Couches respectees : controller -> service -> repository -> domain
- Exceptions typees, jamais generiques
- Toutes les entrees utilisateur validees
- Aucun secret en dur (verifier avec `gitleaks`)
- Logs structures, niveaux corrects, pas de PII
- >= 80% coverage sur le nouveau code
- Pagination sur tout endpoint qui retourne une liste

## Workflow Git / GitHub

- Pas de commit direct sur `main`
- Branches : `<type>/<scope>-<short-description>` (feat/fix/refactor/docs/chore/test/sec/perf)
- Conventional commits : `<type>(<scope>): <description>`
- Issue liee obligatoire (`Closes #XXX`)
- PR template rempli (`/.github/PULL_REQUEST_TEMPLATE.md`)
- Pas de PR > 500 lignes ajoutees (split en plusieurs)
- Une PR > 7 jours : soit mergee soit fermee
- Force-push sur main interdit

## Decisions architecturales

Toute decision non-triviale et non-locale -> `docs/adr/NNN-titre.md` (format Context / Decision / Consequences / Alternatives).

## Refus & push-back constructif

Une bonne demande utilisateur peut produire un mauvais code. Detecter et proposer mieux.

Format push-back :
1. Acquiescer le besoin ("Je comprends que tu veux X parce que Y")
2. Pointer le risque ("Le probleme avec A : [risque concret]")
3. Proposer mieux ("Je propose B : [benefice]. Tradeoff : [cout honnete]")
4. Laisser decider ("Tu valides B ou tu preferes A pour [raison] ?")

## Architecture IA (specifique projet)

- JAMAIS un seul appel IA pour tout generer
- Decoupe sequentielle : profil -> experiences -> titre -> controle qualite
- L'IA ne doit JAMAIS inventer des chiffres ou des annees d'experience
- Forcer le singulier masculin pour les verbes d'action (Developpe, pas Developpes)
- Varier les structures de phrases (pas toujours verbe + chiffre + resultat)
- Nettoyer le markdown (**gras**, etc.) avant affichage PDF
- Detecter et signaler le contenu qui "sonne IA"
- Ne pas exposer le nom du fournisseur IA (DeepSeek) aux utilisateurs

## CV Best Practices (specifique produit)

- Participes passes au singulier : "Developpe", "Concu", "Optimise"
- Pas de mots cliches : motive, dynamique, passionne, rigoureux
- Accents obligatoires : Developpeur -> Développeur
- Max 10 competences dans le PDF
- Pas de label "Bon" — juste la barre ou rien
- Titres de section sans espacement excessif (pas C O M P E T E N C E S)
- 1 page pour < 5 ans d'experience

## Verification en 5 questions (avant chaque action)

1. Ai-je verifie l'existant (issues, PRs, code) avant de proposer du nouveau ?
2. Ai-je l'evidence concrete de mes claims (commande lancee, fichier lu, sortie vue) ?
3. Ai-je passe les 6 perspectives ?
4. Mon code passerait-il l'audit demain sans me faire honte ?
5. Si 100k users utilisent ca dans 10 ans, qu'est-ce qui va casser en premier ?

Si une reponse est "non" : s'arreter et corriger.
