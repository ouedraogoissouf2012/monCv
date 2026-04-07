# Plan de Test Complet — MonCV Application
> URL : http://localhost:3001 | Backend : http://localhost:8082
> Date : 2026-03-28

---

## MODULE 1 — AUTHENTIFICATION

### T1.1 — Inscription (Register)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 1.1.1 | Naviguer vers `/register` | Formulaire d'inscription affiché | ☐ |
| 1.1.2 | Remplir Prénom=`Test`, Nom=`User`, Email=`test@test.com`, MDP=`Test1234!` → Créer | Redirection vers `/home`, liste CV vide | ☐ |
| 1.1.3 | Email déjà utilisé → Créer | Message d'erreur "email déjà existant" | ☐ |
| 1.1.4 | MDP vide → Créer | Validation bloquante visible | ☐ |
| 1.1.5 | Email invalide (`abc`) → Créer | Validation bloquante visible | ☐ |

### T1.2 — Connexion (Login)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 1.2.1 | Email=`test@test.com`, MDP=`Test1234!` → Connexion | Redirection vers `/home` | ☐ |
| 1.2.2 | Mauvais MDP → Connexion | Message "Email ou mot de passe incorrect" | ☐ |
| 1.2.3 | Email inexistant → Connexion | Message d'erreur affiché | ☐ |
| 1.2.4 | Champs vides → Connexion | Validation bloquante | ☐ |
| 1.2.5 | Appuyer "Pas de compte ? S'inscrire" | Redirection vers `/register` | ☐ |

### T1.3 — Déconnexion (Logout)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 1.3.1 | Cliquer icône déconnexion (sidebar desktop) | Dialog de confirmation affiché | ☐ |
| 1.3.2 | Dialog → Confirmer | Redirection vers `/login`, token supprimé | ☐ |
| 1.3.3 | Dialog → Annuler | Reste sur la page courante | ☐ |
| 1.3.4 | Après déconnexion, naviguer vers `/home` | Redirection automatique vers `/login` | ☐ |

---

## MODULE 2 — LISTE DES CVs (Home)

### T2.1 — Affichage
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 2.1.1 | Connexion avec compte sans CV | Message "Aucun CV" + bouton créer | ☐ |
| 2.1.2 | Connexion avec 2+ CVs | Cards affichées avec titre, date, score complétion | ☐ |
| 2.1.3 | Redimensionner < 900px | Layout mobile (liste verticale) | ☐ |
| 2.1.4 | Redimensionner ≥ 900px | Layout desktop (sidebar + contenu) | ☐ |

### T2.2 — Actions sur un CV existant
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 2.2.1 | Cliquer sur une card CV | Navigation vers détail `/cvs/{id}` | ☐ |
| 2.2.2 | Icône ✏️ Modifier | Navigation vers formulaire d'édition | ☐ |
| 2.2.3 | Icône 📄 Télécharger PDF | PDF téléchargé avec le style sauvegardé | ☐ |
| 2.2.4 | Icône 📋 Dupliquer | Nouveau CV créé avec "(Copie)" dans le titre | ☐ |
| 2.2.5 | Icône 🔗 Partager | Lien public copié dans le presse-papier | ☐ |
| 2.2.6 | Icône 🗑️ Supprimer | Dialog confirmation affiché | ☐ |
| 2.2.7 | Dialog Supprimer → Confirmer | CV retiré de la liste | ☐ |
| 2.2.8 | Dialog Supprimer → Annuler | CV conservé dans la liste | ☐ |

---

## MODULE 3 — FORMULAIRE DE CRÉATION / ÉDITION CV

### T3.1 — Navigation Stepper (Mobile)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.1.1 | Cliquer "Nouveau CV" (FAB) | Formulaire étape 1 (Titre) affiché | ☐ |
| 3.1.2 | Étape 1 vide → Suivant | Validation bloquante "Titre obligatoire" | ☐ |
| 3.1.3 | Titre=`Mon CV Test` → Suivant | Passage à étape 2 (Identité) | ☐ |
| 3.1.4 | Étape 2 → Précédent | Retour étape 1, données conservées | ☐ |
| 3.1.5 | Cliquer cercle numéroté (stepper) | Navigation directe vers l'étape cliquée | ☐ |
| 3.1.6 | Barre de complétion visible | Couleur rouge/orange/vert selon % rempli | ☐ |

### T3.2 — Étape 1 : Titre
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.2.1 | Titre=`Développeur Full Stack` → Suivant | Étape 2 affichée, complétion +10% | ☐ |
| 3.2.2 | Card "Conseils" visible | Tips affichés sous le champ | ☐ |

### T3.3 — Étape 2 : Identité
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.3.1 | Champs Prénom* et Email* vides → Suivant | Validation bloquante sur champs marqués `*` | ☐ |
| 3.3.2 | Taper "Cot" dans le champ Pays | Dropdown autocomplete affichant "Côte d'Ivoire" | ☐ |
| 3.3.3 | Sélectionner "Côte d'Ivoire" | Champ rempli, dropdown fermé | ☐ |
| 3.3.4 | Remplir Prénom=`Issouf`, Nom=`Ouedraogo`, Email=`test@test.com`, Tél=`0544210112`, Ville=`Abidjan` → Suivant | Étape 3 affichée | ☐ |
| 3.3.5 | Upload photo profil | Photo affichée dans le formulaire | ☐ |

### T3.4 — Étape 3 : Expériences
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.4.1 | Cliquer "+ Ajouter une expérience" | Bottom sheet formulaire d'expérience | ☐ |
| 3.4.2 | Remplir Poste=`Développeur`, Entreprise=`DIGIT`, Début=01/2026, cocher "Poste actuel" | Date fin grisée/cachée | ☐ |
| 3.4.3 | Cliquer "✨ Suggérer" (bouton IA) | Suggestions de bullet points affichées | ☐ |
| 3.4.4 | Appliquer une suggestion | Description remplie avec le texte suggéré | ☐ |
| 3.4.5 | Sauvegarder → expérience dans la liste | Tile avec Poste • Entreprise affiché | ☐ |
| 3.4.6 | Modifier une expérience existante | Bottom sheet pré-rempli | ☐ |
| 3.4.7 | Supprimer une expérience | Tile retiré de la liste | ☐ |

### T3.5 — Étape 4 : Formations
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.5.1 | Cliquer "+ Ajouter une formation" | Bottom sheet formulaire formation | ☐ |
| 3.5.2 | Cocher "Formation en cours" | Champ "Date fin" remplacé par badge "En cours" | ☐ |
| 3.5.3 | Sauvegarder avec "En cours" coché | Formation sans date fin dans la liste | ☐ |
| 3.5.4 | Sauvegarder sans "En cours", avec Date fin=03/2020 | Formation avec plage de dates affichée | ☐ |

### T3.6 — Étape 5 : Compétences & Langues
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.6.1 | Ajouter compétence Nom=`Flutter`, Niveau=4 | Tile avec barre niveau affiché | ☐ |
| 3.6.2 | Ajouter langue Langue=`Français`, Niveau=`C1` | Tile langue affiché | ☐ |
| 3.6.3 | Modifier compétence existante | Bottom sheet pré-rempli | ☐ |

### T3.7 — Étape 6 : Certifications & Projets
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.7.1 | Ajouter certification Nom=`AWS`, Organisme=`Amazon` | Tile certification affiché | ☐ |
| 3.7.2 | Ajouter projet Nom=`MonCV App`, Technologies=`Flutter,Spring` | Tile projet affiché | ☐ |

### T3.8 — Sauvegarde
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 3.8.1 | Cliquer "Enregistrer" | Snackbar succès + navigation vers liste ou détail | ☐ |
| 3.8.2 | Perte de connexion → Enregistrer | Message d'erreur réseau affiché | ☐ |

---

## MODULE 4 — DÉTAIL DU CV

### T4.1 — Prévisualisation
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 4.1.1 | Ouvrir détail d'un CV | CV affiché en format document (pas accordion) | ☐ |
| 4.1.2 | Toutes sections remplies | Toutes les sections visibles dans la preview | ☐ |
| 4.1.3 | CV avec peu de données | Sections vides non affichées | ☐ |

### T4.2 — Personnalisation (icône 🎨 palette)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 4.2.1 | Cliquer icône palette | Bottom sheet personnalisation ouvert | ☐ |
| 4.2.2 | Sélectionner template "Créatif" | Grille : "Créatif" surligné | ☐ |
| 4.2.3 | Sélectionner couleur rose (EC4899) | Couleur sélectionnée avec coche ✓ | ☐ |
| 4.2.4 | Sélectionner police "Poppins" | Chip "Poppins" sélectionné | ☐ |
| 4.2.5 | Cliquer "Télécharger avec ce style" | PDF téléchargé avec le nouveau template/couleur/police | ☐ |
| 4.2.6 | Fermer et rouvrir le panneau | Style précédemment choisi conservé | ☐ |

### T4.3 — Amélioration IA (icône ✨)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 4.3.1 | Cliquer icône ✨ | Bottom sheet avec 3 niveaux (Lite/Medium/Max) | ☐ |
| 4.3.2 | Sélectionner "Lite" → Améliorer | Résultat avec sections Avant/Après affiché | ☐ |
| 4.3.3 | Sélectionner "Medium" → Améliorer | Reformulation plus impactante visible | ☐ |
| 4.3.4 | Sélectionner "Max" → Améliorer | Restructuration complète visible | ☐ |
| 4.3.5 | Cliquer "Appliquer" | Snackbar confirmation, sheet fermé | ☐ |
| 4.3.6 | Cliquer "Réessayer" | Retour au sélecteur de niveaux | ☐ |
| 4.3.7 | Sans clé DeepSeek configurée | Message "Mode hors ligne — clé DeepSeek manquante" | ☐ |

### T4.4 — Téléchargement PDF (icône 📄)
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 4.4.1 | Cliquer icône PDF | Spinner affiché pendant la génération | ☐ |
| 4.4.2 | Génération terminée | Fichier `cv-{id}.pdf` téléchargé automatiquement | ☐ |
| 4.4.3 | PDF ouvert | Sections correctes, pas de caractères corrompus | ☐ |
| 4.4.4 | CV style "Moderne" → PDF | Header coloré, bannières bleues | ☐ |
| 4.4.5 | CV style "Classique" → PDF | En-tête centré, divider sous le nom | ☐ |
| 4.4.6 | CV style "Minimaliste" → PDF | Mise en page épurée, texte aéré | ☐ |
| 4.4.7 | CV style "Créatif" → PDF | Sidebar colorée, layout bicolonne | ☐ |
| 4.4.8 | CV style "Executive" → PDF | Nom + info droite, ligne accent | ☐ |

---

## MODULE 5 — PROFIL UTILISATEUR

### T5.1 — Affichage & Modification
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 5.1.1 | Cliquer "Profil" dans la sidebar | Page profil avec email et nom affichés | ☐ |
| 5.1.2 | Modifier Prénom=`IssoufEdited` → Sauvegarder | Confirmation + nom mis à jour | ☐ |

---

## MODULE 6 — COMPORTEMENTS TRANSVERSAUX

### T6.1 — Responsive
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 6.1.1 | Viewport 375px (mobile) | Formulaire en stepper vertical, pas de sidebar | ☐ |
| 6.1.2 | Viewport 1280px (desktop) | Sidebar 250px + contenu, nav Précédent/Suivant | ☐ |

### T6.2 — Hors ligne
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 6.2.1 | Couper réseau | Bandeau jaune "Hors ligne" affiché | ☐ |
| 6.2.2 | Rétablir réseau | Bandeau disparaît, liste rechargée | ☐ |

### T6.3 — Sécurité
| # | Entrée | Sortie attendue | Statut |
|---|--------|-----------------|--------|
| 6.3.1 | Accéder `/home` sans être connecté | Redirection vers `/login` | ☐ |
| 6.3.2 | Token expiré → action CV | Redirection vers `/login` | ☐ |

---

## RÉSUMÉ DES RÉSULTATS

| Module | Total | Passés ✅ | Échoués ❌ | Non testés ☐ |
|--------|-------|-----------|-----------|--------------|
| M1 — Auth | 14 | | | 14 |
| M2 — Liste CV | 10 | | | 10 |
| M3 — Formulaire | 24 | | | 24 |
| M4 — Détail | 16 | | | 16 |
| M5 — Profil | 2 | | | 2 |
| M6 — Transversal | 6 | | | 6 |
| **TOTAL** | **72** | | | **72** |

---

## BUGS CONNUS (à surveiller)
- `Dév"loppeur` → faute de frappe de l'utilisateur, pas un bug app
- Dates identiques début/fin (ex: 03/2020–03/2020) → utilisateur a entré la même date
- IA DeepSeek retourne contenu vide si clé API non configurée → fallback propre géré
