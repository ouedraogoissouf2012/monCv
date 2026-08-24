-- Revocation de session (issue #505).
--
-- token_version est la "generation de sessions" d'un compte : chaque JWT emis
-- porte la valeur courante en claim, et l'authentification rejette tout jeton
-- dont la generation ne correspond plus. Incrementer cette colonne invalide
-- donc d'un seul coup tous les jetons deja emis — access ET refresh — sans
-- avoir a tenir un store de sessions cote serveur.
--
-- DEFAULT 0 : les comptes existants demarrent a la generation 0, exactement la
-- generation pretee aux jetons emis avant cette migration (qui ne portent pas
-- le claim). Voir JwtTokenProvider#matchesTokenVersion : la garantie reste
-- entiere puisque toute revocation porte le compte a une generation >= 1.
ALTER TABLE users
    ADD COLUMN token_version INTEGER NOT NULL DEFAULT 0;
