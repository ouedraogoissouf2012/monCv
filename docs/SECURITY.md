# Politique de securite MonCV

## Matrice d'autorisation des ressources

La verification de propriete est atomique : les ressources privees sont
chargees par leur identifiant et celui du compte JWT. L'API ne fait pas de
lecture globale suivie d'un `403`, afin de ne pas devenir un oracle
d'existence. Le role `ADMIN` n'accorde aucun bypass sur les donnees privees
d'un autre compte ; un administrateur reste proprietaire de ses seules
ressources.

| Surface | Identifiant | Autorisation | Absent ou tiers | Effet externe avant controle |
|---|---|---|---|---|
| `POST /api/ai/enhance-cv` | `cvId` | proprietaire JWT | `404 RESOURCE_NOT_FOUND` | aucun appel IA |
| `POST /api/ai/match-job` | `cvId` | proprietaire JWT | `404 RESOURCE_NOT_FOUND` | aucun appel IA |
| `POST /api/ai/application-messages` | `cvId` | proprietaire JWT | `404 RESOURCE_NOT_FOUND` | aucun appel IA |
| `POST /api/cvs/{id}/variant` | `id` | proprietaire JWT | `404 RESOURCE_NOT_FOUND` | aucune adaptation IA |
| Routes privees `/api/cvs/{id}/...` | `id` | proprietaire JWT | `404 RESOURCE_NOT_FOUND` | aucun export ou partage |
| `GET /api/cvs/{id}/variants` | `id` parent | liste filtree par proprietaire | liste vide | aucun |
| `PUT/DELETE /api/applications/{id}` | `id` | proprietaire JWT | `404 RESOURCE_NOT_FOUND` | aucun |
| `POST/PUT /api/applications` | `cvId` optionnel | proprietaire JWT du CV | `404 RESOURCE_NOT_FOUND` | aucun |
| Routes `/api/cvs/public/{token}` | jeton public | capacite de partage active | `404 RESOURCE_NOT_FOUND` | selon reglages publics |
| `GET /api/uploads/photos/{filename}` | nom UUID | acces public intentionnel | `404` | aucun |

Sans JWT valide, les routes privees retournent `401` avant d'atteindre le
controleur. Les reponses `404` de propriete ne contiennent ni donnees du CV,
ni details internes, ni distinction entre ressource absente et interdite.

## Gestion des secrets

Les mots de passe, jetons, cles API, cles privees et secrets JWT ne doivent
jamais etre ajoutes au code, aux tests, aux captures, aux tickets ou a
l'historique Git.

- En local, utiliser un fichier `.env` ignore par Git.
- En CI et en production, utiliser le gestionnaire de secrets de la plateforme.
- Ne definir aucune valeur de production comme valeur par defaut dans YAML.
- Ne jamais transmettre un secret au client Flutter ou a une variable Web.
- Utiliser des valeurs clairement fictives et limitees aux tests lorsque cela
  est indispensable.

Secrets critiques actuels :

- `DB_PASSWORD`
- `JWT_SECRET`
- `DEEPSEEK_API_KEY`
- `GOOGLE_APPLICATION_CREDENTIALS`
- `SENTRY_DSN`

Les fichiers `.env.example` documentent uniquement les noms des variables. Ils
ne contiennent aucune valeur utilisable.

## Rotation

- rotation immediate apres tout incident ou doute d'exposition ;
- rotation planifiee au minimum trimestrielle pour les cles API externes ;
- rotation a chaque changement d'equipe pour les secrets partages manuellement ;
- apres rotation, verifier les healthchecks et l'absence d'erreurs auth.

## Runbook — Rotation cle DeepSeek + audit pre-prod

Procedure operateur pour remplacer la cle `DEEPSEEK_API_KEY`. A appliquer
apres toute exposition confirmee ou suspectee (cf. incident de mai 2026,
`docs/SECURITY_INCIDENT_2026-05.md`) et lors des rotations planifiees.

Regles absolues pendant l'operation :

- ne jamais afficher, coller, journaliser ni committer la valeur d'une cle ;
- ne jamais reutiliser l'ancienne cle, meme temporairement ;
- l'ordre est strict : deployer la NOUVELLE cle et valider AVANT de revoquer
  l'ancienne, sinon l'IA tombe en panne (le service reste up en mode degrade,
  cf. `AppStartupValidator`, mais la fonctionnalite IA est indisponible).

### 1. Preparer la nouvelle cle

1. Se connecter au tableau de bord DeepSeek (`https://platform.deepseek.com/`).
2. Creer une NOUVELLE cle. Ne pas encore revoquer l'ancienne.
3. La transmettre uniquement via le gestionnaire de secrets ou un canal
   chiffre. Jamais par courriel, ticket, capture ou messagerie en clair.

### 2. Injecter la cle dans le gestionnaire de secrets

1. Enregistrer la valeur sous `DEEPSEEK_API_KEY` dans le gestionnaire de
   secrets de la plateforme de production (jamais dans un fichier suivi).
2. En local uniquement : la placer dans `backend/.env` (ignore par Git). Ne
   definir aucune valeur par defaut dans un YAML suivi.
3. Ne jamais propager la cle vers le client Flutter ou une variable Web : elle
   ne sert qu'au backend (`spring.ai.deepseek.api-key`).

### 3. Redeployer et valider la readiness

1. Redeployer le backend pour qu'il relise le secret (par ex.
   `docker compose -f docker-compose.prod.yml up -d --no-deps --force-recreate backend`,
   ou l'equivalent de la plateforme). `ProductionConfigurationPolicy` reste le
   gate d'autorite : un boot en profil prod echoue si la config est invalide.
2. Controler la SANITE de la configuration avant meme le boot :

   ```bash
   tools/deployment/check-prod-readiness.sh --env <fichier .env.production>
   ```

3. Sonder l'application deployee (readiness + liveness) :

   ```bash
   tools/deployment/check-prod-readiness.sh --health <url actuator>
   ```

4. Verifier specifiquement le composant DeepSeek de `/actuator/health` : il
   doit etre `UP` (cf. `DeepSeekHealthIndicator`, cache 60 s). Un `DOWN` ou un
   `401` provider signale une cle invalide ou mal injectee — corriger avant de
   poursuivre.

### 4. Revoquer l'ancienne cle

1. Une fois la readiness confirmee UP avec la nouvelle cle, revoquer l'ancienne
   dans le tableau de bord DeepSeek.
2. Consulter les journaux d'utilisation DeepSeek de l'ancienne cle pour
   detecter tout appel non legitime, et le signaler le cas echeant.
3. Reverifier `/actuator/health` apres revocation : le composant DeepSeek doit
   rester `UP` (preuve que la nouvelle cle est bien celle utilisee).

### 5. Purge de l'historique si la cle a ete committee

La revocation ne suffit pas si la valeur est entree dans Git : elle reste
lisible dans l'historique. Appliquer alors la procedure de reecriture decrite
dans `docs/SECURITY_INCIDENT_2026-05.md` :

1. cloner un miroir de sauvegarde avant toute reecriture ;
2. reecrire toutes les branches avec `git-filter-repo` ;
3. controler le resultat sur le miroir :

   ```bash
   git log --all -S "sk-" --oneline   # doit ne rien renvoyer
   git fsck --full --strict
   python tools/quality/run_gitleaks.py
   ```

4. forcer la mise a jour des branches, puis demander a chaque contributeur de
   supprimer son clone et de recloner ;
5. contacter GitHub Support pour purger les references PR et caches residuels.

### 6. Cloture

- Confirmer que le scan Gitleaks d'historique complet est vert : declencher le
  workflow `.github/workflows/security.yml` (evenement `workflow_dispatch`), qui
  analyse tout l'historique et fait autorite (cf. section « Controle GitHub »).
- Consigner l'operation (date, operateur, motif) sans jamais y reporter la
  moindre valeur de cle.
- La detection en amont d'une cle DeepSeek au format `sk-...` est assuree par la
  regle `moncv-deepseek-api-key` de `.gitleaks.toml` : le ruleset Gitleaks par
  defaut ne couvre que le format OpenAI (`sk-...T3BlbkFJ...`) et laisserait
  passer une cle DeepSeek.

## Controle avant commit

Installer `pre-commit` et Gitleaks, puis activer le hook :

```bash
python -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```

Le hook utilise le binaire `gitleaks` du systeme. Son installation est decrite
sur le depot officiel Gitleaks. Un commit est refuse si un secret est detecte.

## Controle GitHub

Le workflow `.github/workflows/security.yml` analyse l'historique complet sur
chaque push, chaque pull request et une fois par semaine. Une detection fait
echouer la verification et bloque la fusion lorsque la branche protege exige ce
statut.

GitHub Secret Scanning et Push Protection doivent egalement etre actives dans
les parametres de securite du depot lorsque le plan GitHub le permet.

## Liste blanche

Les exceptions sont centralisees dans `.gitleaks.toml`. Une exception doit :

1. viser une valeur manifestement fictive ;
2. etre limitee a un chemin precis ;
3. expliquer pourquoi elle ne peut pas donner acces a un environnement ;
4. etre revue comme toute modification de securite.

La configuration autorise actuellement uniquement la valeur JWT locale du
profil Spring `dev`. Cette exception devra etre supprimee avec la valeur dans le
cadre de l'issue de suppression du secret JWT par defaut.

## Reponse a un incident

Si un secret entre dans Git, le supprimer dans un commit ulterieur ne suffit
pas. Il faut immediatement :

1. revoquer ou faire tourner le secret chez le fournisseur ;
2. verifier les journaux d'utilisation ;
3. prevenir les responsables du depot et du deploiement ;
4. reecrire l'historique si necessaire ;
5. faire recloner le depot aux contributeurs ;
6. contacter GitHub Support pour purger les references PR et caches residuels.

L'incident DeepSeek de mai 2026 est documente dans
`docs/SECURITY_INCIDENT_2026-05.md`.

## Responsabilites

- proprietaire depot : `@ouedraogoissouf2012`
- responsable technique du secret impacte : mainteneur du scope backend/mobile concerne
- contact escalade plateforme : a formaliser avant exploitation 24/7
