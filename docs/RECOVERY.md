# Sauvegarde et restauration

Ce guide decrit la preuve chiffree de sauvegarde et de restauration de MonCV.
La commande ne remplace pas une politique de retention, un stockage hors site
ni la supervision de l'operateur.

## Garanties

- PostgreSQL est envoye directement de `pg_dump` vers Restic. Aucun dump en
  clair n'est ecrit sur le disque hote.
- Les uploads et la base forment deux snapshots lies par un UUID d'operation
  et le SHA Git deploye.
- Le backend doit etre sain, puis il est arrete proprement pendant la capture
  afin d'eviter une course entre la base et les fichiers.
- Le backend est redemarre dans le nettoyage, y compris apres une erreur.
- Un snapshot partiel est oublie et aucune preuve de succes n'est ecrite.
- `restic check --read-data` valide le depot avant l'ecriture du recu.
- La restauration utilise un PostgreSQL Docker jetable, sans port hote et sans
  reseau, puis restaure les uploads dans un espace de travail temporaire.
- La base de production et les uploads de production ne sont jamais modifies
  par la commande `restore`.
- Les recus JSON ne contiennent ni secret, ni URL de depot, ni contenu
  utilisateur.

La sauvegarde provoque une courte indisponibilite du backend. Planifier son
execution pendant une fenetre de maintenance et superviser le redemarrage.

## Prerequis

- Python 3.12 et `uv` ;
- Docker avec Compose 2.20.0 ou plus recent ;
- Restic 0.19.1 ou plus recent ;
- le stack Compose de production deja demarre et le backend sain ;
- un depot Restic initialise et accessible ;
- un repertoire `backend/uploads` existant, ou un chemin explicite.

Verifier les versions et la configuration avant toute operation :

```bash
uv run --locked python -m tools.recovery check --root /srv/moncv
```

La derniere ligne de sortie standard est un JSON. Un succes ressemble a :

```json
{"action":"check","compose_version":"2.40.0","restic_version":"0.19.1","status":"ok"}
```

## Fichiers de configuration

Quatre variables pilotent la commande :

| Variable | Contenu | Valeur par defaut |
| --- | --- | --- |
| `RECOVERY_COMPOSE_ENV_FILE` | fichier Compose de production | `.env.production` |
| `RESTIC_REPOSITORY_FILE` | chemin du fichier contenant le depot Restic | aucune |
| `RESTIC_PASSWORD_FILE` | chemin du fichier contenant le mot de passe Restic | aucune |
| `RECOVERY_UPLOADS_PATH` | repertoire d'uploads monte par le backend | `backend/uploads` |

Les trois fichiers de configuration doivent etre des fichiers ordinaires,
sans lien symbolique, d'au plus 4 Kio. Sous Linux et macOS, aucun droit groupe
ou autre n'est accepte :

```bash
chmod 600 /etc/moncv/production.env
chmod 600 /etc/moncv/restic-repository
chmod 600 /etc/moncv/restic-password
```

Le fichier depot et le fichier mot de passe contiennent chacun exactement une
ligne, sans espace initial ou final. Ils doivent etre distincts. Le mot de
passe doit avoir au moins 32 caracteres et 12 caracteres differents.

Le fichier depot ne doit pas contenir de credentials, de query string ou de
fragment. En production, utilisez un backend distant Restic, par exemple
`s3:...`, `sftp:...`, `rest:...`, `b2:...`, `azure:...`, `gs:...`,
`rclone:...` ou `swift:...`. Les credentials du fournisseur restent dans son
mecanisme d'identite ou dans les variables reconnues par Restic.

Exemple d'environnement operateur :

```bash
export RECOVERY_COMPOSE_ENV_FILE=/etc/moncv/production.env
export RESTIC_REPOSITORY_FILE=/etc/moncv/restic-repository
export RESTIC_PASSWORD_FILE=/etc/moncv/restic-password
export RECOVERY_UPLOADS_PATH=/srv/moncv/backend/uploads
```

Initialiser une seule fois un nouveau depot :

```bash
restic \
  --repository-file "$RESTIC_REPOSITORY_FILE" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  init
```

Conserver le mot de passe hors du serveur sauvegarde. Sans ce mot de passe, les
snapshots chiffres sont irrecuperables.

## Creer une sauvegarde

Le SHA doit etre le SHA Git complet, en minuscules, de l'image effectivement
deployee. Le parent du recu doit exister et le fichier ne doit pas deja
exister.

```bash
mkdir -p /var/lib/moncv/recovery-receipts
chmod 700 /var/lib/moncv/recovery-receipts

uv run --locked python -m tools.recovery backup \
  --root /srv/moncv \
  --deployed-sha 0123456789abcdef0123456789abcdef01234567 \
  --receipt /var/lib/moncv/recovery-receipts/backup-20260726.json
```

Ne relancez pas la commande avec le meme chemin de recu. Le stockage est
atomique et refuse tout ecrasement.

Apres succes, verifier que le backend est sain :

```bash
docker compose \
  --env-file /etc/moncv/production.env \
  -f /srv/moncv/docker-compose.yml \
  -f /srv/moncv/docker-compose.prod.yml \
  ps backend
```

## Prouver une restauration

Une preuve de restauration lit le recu de sauvegarde, exige les deux snapshots
exacts et valide :

- la lisibilite complete des snapshots Restic ;
- le nombre et la derniere migration Flyway ;
- l'arborescence, la taille et le SHA-256 des uploads ;
- le nettoyage du conteneur et de l'espace de travail jetables.

Le recu de restauration n'est ecrit qu'apres ce nettoyage.

```bash
uv run --locked python -m tools.recovery restore \
  --root /srv/moncv \
  --backup-receipt /var/lib/moncv/recovery-receipts/backup-20260726.json \
  --receipt /var/lib/moncv/recovery-receipts/restore-20260726.json
```

Archivez les deux recus avec les journaux de supervision de la fenetre. Un
recu prouve une execution technique, pas la conservation future du depot.

## Exercice local gratuit

Le depot local est interdit par defaut. Il est autorise uniquement pour un
exercice explicite et ne constitue jamais une sauvegarde de production.
Utilisez un depot hors de l'arborescence des uploads :

```bash
printf '%s\n' '/tmp/moncv-restic-drill' > /tmp/restic-repository
printf '%s\n' 'local-drill-password-with-32-unique-value-7Qx!' \
  > /tmp/restic-password
chmod 600 /tmp/restic-repository /tmp/restic-password

export RESTIC_REPOSITORY_FILE=/tmp/restic-repository
export RESTIC_PASSWORD_FILE=/tmp/restic-password

restic \
  --repository-file "$RESTIC_REPOSITORY_FILE" \
  --password-file "$RESTIC_PASSWORD_FILE" \
  init

uv run --locked python -m tools.recovery check \
  --root /srv/moncv \
  --allow-local-repository
```

Ajoutez `--allow-local-repository` a `backup` et `restore` pendant tout
l'exercice. Supprimez ensuite le depot, les recus et les fichiers de
configuration jetables.

## Codes de sortie

| Code | Categorie | Action operateur |
| ---: | --- | --- |
| `0` | succes | archiver le recu et les preuves |
| `10` | configuration ou outils | corriger les fichiers, permissions ou versions |
| `20` | sauvegarde | verifier le backend, Restic et le redemarrage |
| `30` | restauration | inspecter la cible jetable et les snapshots |
| `40` | recu | utiliser un chemin absolu neuf et prive |
| `50` | donnees ou entree invalide | verifier le SHA, Flyway et le contrat |
| `70` | erreur interne | conserver les codes JSON et ouvrir un incident |

En erreur, seul un tableau de codes stables est ecrit sur stderr :

```json
{"codes":["BACKUP_INCOMPLETE"],"status":"error"}
```

La commande masque stderr des outils externes pour eviter une fuite de secret.
Consultez les journaux Docker separement, avec un acces restreint, sans les
publier dans une issue.

## Incident et limites

Si `BACKEND_RESTART_FAILED` apparait, la restauration de service est
prioritaire : controlez `docker compose ps backend`, puis demarrez uniquement
le backend avec la meme configuration de production. N'annoncez jamais la
sauvegarde comme valide si le recu n'existe pas.

En cas d'echec de nettoyage, recherchez les ressources portant l'identifiant
de l'exercice. Ne supprimez jamais un conteneur sur son seul nom : confirmez
son identifiant et ses labels d'appartenance.

La retention et la planification doivent etre configurees separement avec une
politique documentee et testee. Pour plusieurs instances, des ecritures
continues ou un RPO inferieur a l'intervalle de sauvegarde, migrez vers
PostgreSQL PITR avec archivage WAL et vers un stockage objet versionne. Gardez
Restic pour les preuves chiffrees tant que les exercices de restauration
restent automatises et mesures.
