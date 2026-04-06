# Regles du projet MonCV

## Qualite du code
- Toujours proposer la MEILLEURE solution architecturale, pas la plus rapide
- Si une solution necessite plus de fichiers/temps, c'est OK
- Ne jamais coder en dur (pas de "Bon" fixe, pas de valeurs magiques)
- Chaque fonctionnalite doit avoir : validation, gestion d'erreur, tests

## Architecture IA
- JAMAIS un seul appel IA pour tout generer
- Decoupe sequentielle : profil → experiences → titre → controle qualite
- L'IA ne doit JAMAIS inventer des chiffres ou des annees d'experience
- Forcer le singulier masculin pour les verbes d'action (Developpe, pas Developpes)
- Varier les structures de phrases (pas toujours verbe + chiffre + resultat)
- Nettoyer le markdown (**gras**, etc.) avant affichage PDF
- Detecter et signaler le contenu qui "sonne IA"

## CV Best Practices
- Participes passes au singulier : "Developpe", "Concu", "Optimise"
- Pas de mots cliches : motive, dynamique, passionne, rigoureux
- Accents obligatoires : Developpeur → Développeur
- Max 10 competences dans le PDF
- Pas de label "Bon" — juste la barre ou rien
- Titres de section sans espacement excessif (pas C O M P E T E N C E S)
- 1 page pour < 5 ans d'experience

## Issues et PRs
- Chaque correction = issue + PR + commit descriptif
- Expliquer ce qui a ete fait pour que l'utilisateur apprenne

## Interdictions
- Ne pas exposer le nom du fournisseur IA (DeepSeek) aux utilisateurs
- Ne pas commiter de cles API dans le code
- Ne pas laisser de debug print() en production
