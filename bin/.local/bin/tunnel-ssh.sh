#!/usr/bin/env bash
set -euo pipefail

# ==== Ajustes generales ====
SSH_BIN="/usr/bin/ssh"
SSH_CONFIG="/Users/rubensilvarodriguez/.ssh/config"
LOG_DIR="/tmp/ssh-tunnels"
mkdir -p "$LOG_DIR"

# Si usas Bitwarden agent y quieres hacerlo robusto en launchd,
# puedes fijar el socket aquí (si no, comenta estas 2 líneas).
export SSH_AUTH_SOCK="/Users/rubensilvarodriguez/.bitwarden-ssh-agent.sock"

# ==== Helpers ====
is_listening() {
  local port="$1"
  /usr/sbin/lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
}

start_tunnel() {
  local name="$1"
  local host="$2"
  local lport="$3"
  local rhost="$4"
  local rport="$5"

  local out="$LOG_DIR/${name}.out"
  local err="$LOG_DIR/${name}.err"

  if is_listening "$lport"; then
    echo "[$(date)] SKIP: $name (localhost:$lport ya está en uso)" | tee -a "$err"
    return 0
  fi

  echo "[$(date)] START: $name 127.0.0.1:$lport -> $rhost:$rport via $host" | tee -a "$out"

  # -N: no shell
  # -L: local forward
  # ExitOnForwardFailure: si no puede abrir el forward, falla
  # ServerAlive*: mantiene vivo el túnel
  # -F: usa tu ssh config (claves/usuarios por host)
  "$SSH_BIN" -F "$SSH_CONFIG" -N \
    -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -o BatchMode=yes \
    -L "${lport}:${rhost}:${rport}" \
    "$host" >>"$out" 2>>"$err" &
}

# Si el job muere, cierra todos los ssh hijos.
cleanup() {
  pkill -P $$ "$SSH_BIN" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# ==== TÚNELES (AJUSTA AQUÍ) ====
# Patrón: start_tunnel "<nombre>" "<host (según ~/.ssh/config)>" <puerto_local> <host_remoto> <puerto_remoto>

# expomark rc*
start_tunnel "expomark-rc1-mysql" "do.rc1.expomark.es" 13306 127.0.0.1 3306
start_tunnel "expomark-rc2-mysql" "do.rc2.expomark.es" 13307 127.0.0.1 3306
start_tunnel "expomark-rc3-mysql" "do.rc3.expomark.es" 13308 127.0.0.1 3306
start_tunnel "expomark-rc4-mysql" "do.rc4.metech.es"   13309 127.0.0.1 3306

# expomark cbcm
start_tunnel "expomark-cbcm-mysql" "do.cbcm.expomark.es" 13310 127.0.0.1 3306

# tedae fr1 (si también quieres)
start_tunnel "do-fr1-mysql" "do.fr1.datarena.tech" 13311 127.0.0.1 3306

# ams3db.conferenciasyformacion.com
start_tunnel "conferencias-mysql" "ams3db.conferenciasyformacion.com" 13312 127.0.0.1 3306

# vps.ovh.wyrko.es
start_tunnel "ens-mysql" "vps.ovh.wyrko.es" 13313 127.0.0.1 3306

# ==== Mantener el proceso vivo ====
wait
