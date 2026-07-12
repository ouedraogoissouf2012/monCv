# Incident de securite DeepSeek - mai 2026

## Resume

Une cle API DeepSeek a ete ajoutee par erreur comme valeur par defaut dans la
configuration Spring, puis retiree des fichiers courants. Sa suppression dans
un commit ulterieur ne l'a pas retiree de l'historique Git.

L'incident est traite comme critique : toute cle publiee doit etre consideree
comme compromise, meme si aucun usage abusif n'a ete observe.

## Perimetre

- Secret concerne : ancienne cle DeepSeek, valeur volontairement omise.
- Fichier d'origine : `backend/src/main/resources/application.yml`.
- Historique affecte : 2 commits, ancetres de 37 branches distantes.
- Tags affectes : aucun.
- Contributeurs a informer : tous les utilisateurs possedant un clone local.

## Actions de remediation

1. Revoquer la cle exposee dans le tableau de bord DeepSeek.
2. Faire tourner toutes les autres cles DeepSeek utilisees par l'application.
3. Mettre les nouvelles valeurs uniquement dans le gestionnaire de secrets de
   production et dans les variables d'environnement locales non versionnees.
4. Creer un clone miroir de sauvegarde avant toute reecriture.
5. Reecrire toutes les branches avec `git-filter-repo`.
6. Verifier l'historique reecrit avec Git et Gitleaks.
7. Forcer la mise a jour des branches et demander un nouveau clone a chaque
   contributeur.

## Verification requise

Les controles suivants doivent etre executes sur le miroir avant publication :

```bash
git log --all -S "DEEPSEEK_KEY_" --oneline
git fsck --full --strict
gitleaks git --redact
```

Le premier controle ne doit produire aucune ligne, `git fsck` doit terminer
sans erreur et Gitleaks ne doit signaler aucune fuite.

## Consignes apres le force-push

Les anciens clones contiennent toujours le secret et ne doivent pas servir a
republier une ancienne branche. Chaque contributeur doit supprimer son clone et
recloner le depot. Les branches locales utiles doivent etre exportees sous forme
de patch, controlees pour les secrets, puis rejouees sur le nouvel historique.

## Prevention

- Ne jamais definir de secret comme valeur par defaut dans un fichier suivi.
- Utiliser uniquement des variables d'environnement ou un gestionnaire de
  secrets pour les environnements deployes.
- Activer Gitleaks en pre-commit et dans la CI.
- Activer GitHub secret scanning et push protection.
- Revoquer immediatement toute valeur apparaissant dans un commit, une PR, un
  ticket, une capture ou un journal partage.

Le suivi preventif est porte par l'issue de securite consacree a Gitleaks et a
la protection des pushes.
