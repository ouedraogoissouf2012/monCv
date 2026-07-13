# Politique de securite MonCV

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
