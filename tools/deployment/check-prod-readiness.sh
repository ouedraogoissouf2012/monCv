#!/usr/bin/env sh
# Verification de preparation a la production (issue #488).
#
# Deux modes, combinables :
#   --env <fichier>  : verifie la SANITE des valeurs du fichier .env.production
#                      (le fichier de secrets interpole par docker-compose.prod.yml).
#                      Presence + longueur + placeholder + format, en miroir de
#                      backend/.../config/ProductionConfigurationPolicy.
#   --health <url>   : sonde une app DEPLOYEE via actuator readiness + liveness
#                      (ex. via `docker compose exec backend`, ou sur staging).
#
# Sans --env, les variables sont lues depuis l'ENVIRONNEMENT du shell courant
# (utile en conteneur/CI ou les secrets sont deja exportes).
#
# PERIMETRE ET COMPLEMENTARITE (pas de duplication) :
#   * tools/deployment/compose_contract.py = preflight STRUCTUREL : rend le merge
#     Compose et valide services/reseaux/ports/SHA d'image + PRESENCE des vars.
#     Il exige docker + uv. Il ne juge PAS la qualite des valeurs.
#   * Ce script = SANITE DES VALEURS (longueur, placeholder, https, base64-32,
#     regex) SANS docker, + un smoke de SANTE runtime. Il attrape en amont un
#     secret present-mais-faible (ex. JWT_SECRET trop court) que le contrat
#     structurel laisse passer mais que ProductionConfigurationPolicy REJETTE au
#     boot (crash-loop). Il ne verifie PAS les flags codes en dur dans le compose
#     (SPRING_PROFILES_ACTIVE, DB_URL, AI_FALLBACK_ENABLED...) : ils ne sont pas
#     dans .env.production, c'est le role de compose_contract.py.
#   * ProductionConfigurationPolicy (Java) reste le GATE d'autorite : il refuse
#     le demarrage en profil prod si la config est invalide. Un boot reussi
#     (readiness UP) est la preuve definitive ; ce script est un garde-fou amont.
set -eu

# ---------------------------------------------------------------- presentation
if [ -t 1 ]; then
  C_RED=$(printf '\033[31m'); C_GRN=$(printf '\033[32m')
  C_YLW=$(printf '\033[33m'); C_RST=$(printf '\033[0m')
else
  C_RED=; C_GRN=; C_YLW=; C_RST=
fi

FAILURES=0
WARNINGS=0
fail() { printf '%s  FAIL%s  %s\n' "$C_RED" "$C_RST" "$1"; FAILURES=$((FAILURES + 1)); }
warn() { printf '%s  WARN%s  %s\n' "$C_YLW" "$C_RST" "$1"; WARNINGS=$((WARNINGS + 1)); }
ok()   { printf '%s  OK  %s  %s\n' "$C_GRN" "$C_RST" "$1"; }

usage() {
  cat <<'USAGE'
Usage: check-prod-readiness.sh [--env <fichier>] [--health <base-url>]

  --env <fichier>   Sanite des valeurs d'un .env.production (secrets interpoles).
  --health <url>    Sonde actuator readiness + liveness d'une app deployee.
                    L'URL doit atteindre actuator (dans le conteneur backend via
                    `docker compose exec`, ou un port expose sur staging), ex.
                    --health http://127.0.0.1:8082
  --help            Affiche cette aide.

Sans --env, les variables sont lues depuis l'environnement du shell courant.
Sortie: code 0 si aucune FAIL, code 1 sinon.
USAGE
}

# --------------------------------------------------------------------- args
ENV_FILE=
HEALTH_URL=
CHECK_CONFIG=0
while [ $# -gt 0 ]; do
  case "$1" in
    --env)    ENV_FILE=${2:?--env attend un chemin de fichier}; CHECK_CONFIG=1; shift 2 ;;
    --health) HEALTH_URL=${2:?--health attend une URL}; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Argument inconnu: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done
# Par defaut (aucun mode explicite) : verifie l'environnement courant.
if [ -z "$HEALTH_URL" ] && [ "$CHECK_CONFIG" -eq 0 ]; then
  CHECK_CONFIG=1
fi
if [ -n "$ENV_FILE" ] && [ ! -f "$ENV_FILE" ]; then
  printf 'Fichier introuvable: %s\n' "$ENV_FILE" >&2
  exit 2
fi

# Lit une variable depuis le fichier --env (derniere occurrence, guillemets
# retires) ou, a defaut, depuis l'environnement exporte. Ne source jamais le
# fichier (evite l'execution de code arbitraire).
get_var() {
  if [ -n "$ENV_FILE" ]; then
    grep -E "^[[:space:]]*$1=" "$ENV_FILE" 2>/dev/null | tail -1 \
      | sed -e "s/^[[:space:]]*$1=//" \
            -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//"
  else
    eval "printf '%s' \"\${$1:-}\""
  fi
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

is_placeholder() {
  lv=$(lower "$1")
  [ -z "$lv" ] && return 0
  case " change_me change-me changeme dummy password placeholder postgres secret tbd todo " in
    *" $lv "*) return 0 ;;
  esac
  case "$lv" in
    '<'*|change_me_*|change-me-*|deepseek_key_*|dev-compose-only-*|integrationtest-*|moncv-dev-only-*|replace_*|replace-*|testonly-*|your-*|your_*) return 0 ;;
  esac
  return 1
}

# check_secret NOM LONGUEUR_MIN
check_secret() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (secret requis en prod)"; return; fi
  if is_placeholder "$v"; then fail "$1 = valeur placeholder/exemple (a remplacer)"; return; fi
  if [ "${#v}" -lt "$2" ]; then fail "$1 trop court (${#v} car., minimum $2)"; return; fi
  ok "$1 present et non trivial (${#v} car.)"
}

check_sha40() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (SHA Git complet requis, cf. runbook)"; return; fi
  if printf '%s' "$v" | grep -Eq '^[0-9a-f]{40}$'; then
    ok "$1 : SHA Git 40 hex"
  else
    fail "$1 doit etre un SHA Git complet de 40 caracteres hex minuscules"
  fi
}

check_db_username() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant"; return; fi
  if is_placeholder "$v"; then fail "$1 = valeur placeholder (ex. 'postgres')"; return; fi
  if printf '%s' "$v" | grep -Eq '^[A-Za-z_][A-Za-z0-9_-]{2,62}$'; then
    ok "$1 present et valide"
  else
    fail "$1 format invalide (attendu ^[A-Za-z_][A-Za-z0-9_-]{2,62}$)"
  fi
}

# check_positive_int NOM  (duree en ms sans defaut compose -> requis)
check_positive_int() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (entier en millisecondes requis)"; return; fi
  case "$v" in ''|*[!0-9]*) fail "$1 doit etre un entier positif (ms), trouve '$v'"; return ;; esac
  if [ "$v" -le 0 ]; then fail "$1 doit etre > 0"; return; fi
  ok "$1 = $v"
}

check_origins() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (origines CORS requises)"; return; fi
  bad=0
  oldifs=$IFS; IFS=','
  for o in $v; do
    o=$(printf '%s' "$o" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$o" ] && continue
    case "$o" in https://*) ;; *) bad=1 ;; esac
    case "$o" in *'*'*) bad=1 ;; esac
    lo=$(lower "$o")
    case "$lo" in
      *localhost*|*//127.*|*'//[::1]'*|*example.com*|*.test|*.test/*|*.invalid|*.invalid/*) bad=1 ;;
    esac
  done
  IFS=$oldifs
  if [ "$bad" -ne 0 ]; then
    fail "$1 invalide : chaque origine doit etre https://<domaine-reel> (pas de *, pas de http, pas de localhost/example.com)"
  else
    ok "$1 : origines HTTPS valides"
  fi
}

# check_https_url NOM  ; MODE=warn rend l'echec non bloquant (valeur optionnelle)
check_https_url() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then
    [ "${2:-fail}" = "warn" ] && warn "$1 vide" || fail "$1 manquant"
    return
  fi
  case "$v" in
    https://*) case "$v" in *'*'*) fail "$1 ne doit pas contenir '*'";; *) ok "$1 : URL https";; esac ;;
    *) fail "$1 doit etre une URL https://" ;;
  esac
}

check_b64_32() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant"; return; fi
  if is_placeholder "$v"; then fail "$1 = valeur placeholder/exemple"; return; fi
  n=$(printf '%s' "$v" | base64 -d 2>/dev/null | wc -c | tr -d '[:space:]')
  if [ "$n" = "32" ]; then
    ok "$1 : cle 32 octets base64"
  else
    fail "$1 doit decoder vers exactement 32 octets base64 (openssl rand -base64 32)"
  fi
}

check_google_client() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant"; return; fi
  if printf '%s' "$v" | grep -Eq '^[A-Za-z0-9-]{10,}\.apps\.googleusercontent\.com$'; then
    ok "$1 : format Google OAuth valide"
  else
    fail "$1 doit finir par .apps.googleusercontent.com"
  fi
}

# Miroir de ProductionConfigurationPolicy.validHost : hote nu (FQDN), pas de
# schema/espace/wildcard, pas d'hote reserve ou local.
check_mail_host() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (hote SMTP requis quand MAIL_ENABLED=true)"; return; fi
  if is_placeholder "$v"; then fail "$1 = valeur placeholder/exemple"; return; fi
  case "$v" in *' '*|*'*'*|*://*) fail "$1 doit etre un hote nu (ex. smtp.example.org), sans schema ni espace"; return ;; esac
  lv=$(lower "$v")
  case "$lv" in
    localhost|*.localhost|127.*|::1|*.test|*.invalid|example.com|*.example.com|*.example)
      fail "$1 pointe vers un hote reserve/local"; return ;;
  esac
  if printf '%s' "$v" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$'; then
    ok "$1 present et valide ($v)"
  else
    fail "$1 format d'hote invalide"
  fi
}

# MAIL_PORT a un defaut compose (587) -> vide = non bloquant.
check_mail_port() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then warn "$1 vide : defaut 587 (STARTTLS) utilise"; return; fi
  case "$v" in ''|*[!0-9]*) fail "$1 doit etre un entier (port), trouve '$v'"; return ;; esac
  if [ "$v" -ge 1 ] && [ "$v" -le 65535 ]; then ok "$1 = $v"; else fail "$1 hors plage 1-65535"; fi
}

check_mail_user() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (identifiant SMTP requis)"; return; fi
  if is_placeholder "$v"; then fail "$1 = valeur placeholder/exemple"; return; fi
  ok "$1 present"
}

check_email() {
  v=$(get_var "$1")
  if [ -z "$v" ]; then fail "$1 manquant (adresse expediteur requise)"; return; fi
  if is_placeholder "$v"; then fail "$1 = valeur placeholder/exemple"; return; fi
  if printf '%s' "$v" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$'; then
    ok "$1 : adresse email valide"
  else
    fail "$1 doit etre une adresse email valide (ex. no-reply@moncv.app)"
  fi
}

# ------------------------------------------------------------- verif config
if [ "$CHECK_CONFIG" -eq 1 ]; then
  if [ -n "$ENV_FILE" ]; then
    printf '\n== Sanite .env.production : %s ==\n' "$ENV_FILE"
  else
    printf '\n== Sanite .env.production : environnement du shell ==\n'
  fi

  # Secrets interpoles par docker-compose.prod.yml (source de verite :
  # .env.production.example + les ${VAR} du compose). Les flags codes en dur
  # dans le compose ne sont volontairement PAS verifies ici (cf. entete).
  check_sha40      TAG
  check_db_username DB_USERNAME
  check_secret     DB_PASSWORD 16
  check_google_client GOOGLE_CLIENT_ID
  check_secret     JWT_SECRET 64
  check_positive_int JWT_EXPIRATION
  check_positive_int JWT_REFRESH_EXPIRATION
  check_origins    ALLOWED_ORIGINS
  check_secret     DEEPSEEK_API_KEY 16
  check_b64_32     PUBLIC_LINK_ENCRYPTION_KEY
  check_origins    PUBLIC_MEDIA_ALLOWED_ORIGINS

  # Optionnels (un defaut compose existe, ou desactivable).
  check_https_url  DEEPSEEK_BASE_URL warn
  sentry=$(get_var SENTRY_DSN)
  if [ -z "$sentry" ]; then
    warn "SENTRY_DSN vide : aucune remontee d'erreur (monitoring desactive)"
  else
    check_https_url SENTRY_DSN
  fi
  webport=$(get_var WEB_PORT)
  if [ -n "$webport" ]; then
    case "$webport" in
      ''|*[!0-9]*) warn "WEB_PORT non numerique ('$webport'), defaut 8080 utilise si absent" ;;
      *) [ "$webport" -ge 1 ] && [ "$webport" -le 65535 ] && ok "WEB_PORT = $webport" \
           || warn "WEB_PORT hors plage 1-65535 ('$webport')" ;;
    esac
  fi

  # Envoi email (reset password, issues #381/#487). Miroir de la validation
  # conditionnelle de ProductionConfigurationPolicy.validateMail :
  #   MAIL_ENABLED absent/false -> repli logging, rien a exiger (sur par defaut).
  #   MAIL_ENABLED=true          -> creds SMTP requises et valides.
  mail_enabled=$(lower "$(get_var MAIL_ENABLED)")
  case "$mail_enabled" in
    true)
      check_mail_host  MAIL_HOST
      check_mail_port  MAIL_PORT
      check_mail_user  MAIL_USERNAME
      check_secret     MAIL_PASSWORD 8
      check_email      MAIL_FROM
      ;;
    ''|false)
      ok "MAIL_ENABLED absent/false : reset password par email desactive (repli logging)"
      ;;
    *)
      fail "MAIL_ENABLED doit valoir true ou false (trouve '$mail_enabled')"
      ;;
  esac
fi

# --------------------------------------------------------------- verif sante
if [ -n "$HEALTH_URL" ]; then
  printf '\n== Sante runtime : %s ==\n' "$HEALTH_URL"
  if ! command -v curl >/dev/null 2>&1; then
    fail "curl introuvable : impossible de sonder l'app"
  else
    base=${HEALTH_URL%/}
    for ep in readiness liveness; do
      url="$base/actuator/health/$ep"
      attempt=1; up=0
      while [ "$attempt" -le 5 ]; do
        body=$(curl -fsS --max-time 5 "$url" 2>/dev/null || printf '')
        case "$body" in *'"status":"UP"'*) up=1; break ;; esac
        attempt=$((attempt + 1)); sleep 3
      done
      if [ "$up" -eq 1 ]; then ok "$ep : UP"; else fail "$ep : indisponible ($url)"; fi
    done
  fi
fi

# ------------------------------------------------------------------- resume
printf '\n== Resume : %s FAIL, %s WARN ==\n' "$FAILURES" "$WARNINGS"
if [ "$FAILURES" -ne 0 ]; then
  printf '%sNON PRET pour la production : corriger les FAIL ci-dessus.%s\n' "$C_RED" "$C_RST"
  exit 1
fi
printf '%sAucune FAIL. Rappel : le gate d autorite reste le boot en profil prod%s\n' "$C_GRN" "$C_RST"
printf 'et une readiness UP apres deploiement.\n'
exit 0
