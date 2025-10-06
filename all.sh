#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# función para Imprimir título 
pt(){
  local title="$1"
  local len=${#title}
  printf '┌%s┐\n' "$(printf '─%.0s' $(seq 1 $len))"
  printf '│%s│\n' "$title"
  printf '└%s┘\n' "$(printf '─%.0s' $(seq 1 $len))"
}

echo "===================================================================================="
# Información del sistema 
pt "Sistema"
uname -a || true
lsb_release -a 2>/dev/null || true
uptime || true

echo "===================================================================================="
# Información de procesos
pt "Top 5 procesos (memoria)"
printf "%-6s %6s %7s  %s\n" "PID" "%MEM" "RSS(MB)" "USER/CMD"
ps -eo pid,pmem,rss,user:8,comm --no-headers --sort=-pmem \
  | head -n 5 \
  | awk '{printf "%-6s %6.1f %7.1f  %s/%s\n",$1,$2,$3/1024,$4,$5}'

pt "Top 5 procesos (CPU)"
printf "%-6s %6s %7s  %s\n" "PID" "%CPU" "RSS(MB)" "USER/CMD"
ps -eo pid,pcpu,rss,user:8,comm --no-headers --sort=-pcpu \
  | head -n 5 \
  | awk '{printf "%-6s %6.1f %7.1f  %s/%s\n",$1,$2,$3/1024,$4,$5}'

echo "===================================================================================="
# Conexión 
pt "Prueba de conexión"
if ping -c 4 8.8.8.8; then
  echo "Ping correcto"
else
  echo "Ping fallido (no hay conectividad hacia 8.8.8.8)" >&2
fi

echo "===================================================================================="

pt "Interfaces"
ip -br a || true

echo "===================================================================================="

pt "Rutas"
ip route show || true

echo "===================================================================================="

pt "Puertos escuchando (ss)"
ss -tuln || true

echo "===================================================================================="

pt "Tabla ARP"
arp -n 2>/dev/null || true

echo "===================================================================================="

pt "Reglas firewall (nft/iptables)"
if command -v nft >/dev/null 2>&1; then
  nft list ruleset | sed -n '1,40p'
elif command -v iptables >/dev/null 2>&1; then
  iptables -L -n -v || true
fi

echo "===================================================================================="

pt "Test de velocidad"
if command -v speedtest >/dev/null 2>&1; then
  # Si speedtest falla, no termina el script
  speedtest || echo "speedtest falló, omitiendo..." >&2
else
  echo "speedtest no instalado, omitiendo..." >&2
fi

echo "===================================================================================="

pt "Particiones y Espacio en disco y tipo de FS"
lsblk -f || echo "lsblk falló, continúo..." >&2
blkid || true


echo "===================================================================================="


pt "Uso disco"
df -h || true
pt "Inodos"
df -i || true

# Archivos/dirs más grandes 
pt "Top archivos (du)"
du -xh / 2>/dev/null | sort -rh | head -n 20 || true
# O en /home
du -xh /home 2>/dev/null | sort -rh | head -n 20 || true

echo "===================================================================================="
  
pt "Memoria"
free -h || true
vmstat 1 2 2>/dev/null || true   

echo "===================================================================================="

pt "Escaneo de la red"
# Escaneo de la red: TARGET se pasa por parámetro
TARGET="${1:-}"
shift || true

if [ -z "$TARGET" ]; then
  echo "Falta TARGET" >&2
  exit 2
fi

if ! printf '%s\n' "$TARGET" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'; then
  echo "Objetivo no válido: $TARGET" >&2
  exit 3
fi

echo "=== Ejecutando nmap en: $TARGET ==="

if [ $# -eq 0 ]; then
  echo "No se pasaron opciones: uso por defecto: -p- -sV -T4 (escanea todos los puertos y detecta servicios)"
  if command -v nmap >/dev/null 2>&1; then
    if [ "$EUID" -ne 0 ]; then
      echo "No eres root: intentaré ejecutar nmap sin sudo (puede dar menos precisión)..." >&2
      nmap -p- -sV -T4 "$TARGET" || echo "nmap falló o se interrumpió, continúo..." >&2
    else
      # Con root -> ejecuta con permisos completos
      nmap -p- -sV -T4 "$TARGET" || echo "nmap falló, continúo..." >&2
    fi
  else
    echo "nmap no está instalado, omitiendo escaneo." >&2
  fi
else
  echo "Usando opciones de usuario: $@"
  # Si fallan, no abortar todo
  nmap "$@" "$TARGET" || echo "nmap con opciones falló, continúo..." >&2
fi

echo "===================================================================================="

pt "Usuarios conectados"
who || true
w || true

pt "Ultimos logins"
last -n 10 || true

# El bloque de /etc/shadow (requiere root)
if [ "$EUID" -eq 0 ]; then
  pt "Última actualización de contraseña"
  getent passwd | awk -F: '($3>=1000 && $3!=65534){print $1}' | while read -r u; do
    lastchg=$(awk -F: -v user="$u" '$1==user{print $3; exit}' /etc/shadow)
    if [ -z "$lastchg" ] || ! printf '%s' "$lastchg" | grep -Eq '^[0-9]+$'; then
      echo "$u: (sin dato)"
    else
      date -d "1970-01-01 +${lastchg} days" +"%F" || echo "$u: (error conv)"
    fi
  done
fi


echo "===================================================================================="


# Mostrar última fecha de cambio de contraseña (UID >= 1000)
title="Mostrar última fecha de cambio de contraseña"
pt "Mostrar última fecha de cambio de contraseña"

echo "=== Última fecha de actualización de la contraseña ==="
getent passwd | awk -F: '($3>=1000 && $3!=65534){print $1}' | while read -r u; do
  # obtener el campo 3 de /etc/shadow (días desde 1970-01-01)
  lastchg=$(awk -F: -v user="$u" '$1==user{print $3; exit}' /etc/shadow)

  if [ -z "$lastchg" ] || ! printf '%s' "$lastchg" | grep -Eq '^[0-9]+$'; then
    echo "$u: (sin dato en /etc/shadow)"
    continue
  fi

  # si el valor es 0 o negativo lo consideramos sin dato útil
  if [ "$lastchg" -le 0 ]; then
    echo "$u: (sin dato en /etc/shadow)"
    continue
  fi

  # convertir días desde epoch a fecha legible
  fecha=$(date -d "1970-01-01 +${lastchg} days" +"%F" 2>/dev/null || true)
  echo "$u: $fecha"
done


echo "===================================================================================="

pt "Comprobaciones externas"

# --- Comprobación HTTP (código de estado) ---
if command -v curl >/dev/null 2>&1; then
  URL="https://www.google.com"
  echo -n "HTTP $URL ... "
  # obtenemos solo el código HTTP en un máximo de 5s
  http_code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$URL" 2>/dev/null) || http_code="000"
  case "$http_code" in
    200) echo "OK (HTTP 200)";;
    000) echo "ERROR (no respuesta / timeout)";;
    *)   echo "HTTP $http_code";;
  esac
else
  echo "curl no instalado — omitiendo comprobación HTTP" >&2
fi

# --- Comprobación DNS usando un resolver público (Cloudflare 1.1.1.1) ---
RESOLVER="1.1.1.1"
HOSTNAME="example.com"
if command -v dig >/dev/null 2>&1; then
  echo -n "DNS (dig @$RESOLVER -> $HOSTNAME) ... "
  dns_ips=$(dig +short @"$RESOLVER" "$HOSTNAME" A +time=2 +tries=1)
  if [ -z "$dns_ips" ]; then
    echo "Sin respuesta"
  else
    echo "OK → $dns_ips"
  fi
elif command -v host >/dev/null 2>&1; then
  echo -n "DNS (host $HOSTNAME @$RESOLVER) ... "
  dns_out=$(host "$HOSTNAME" "$RESOLVER" 2>/dev/null) || dns_out=""
  if printf '%s' "$dns_out" | grep -q 'has address'; then
    printf 'OK → %s\n' "$(printf '%s' "$dns_out" | awk '/has address/ {print $4}' | xargs)"
  else
    echo "Sin respuesta"
  fi
else
  echo "dig/host no instalados — omitiendo comprobación DNS" >&2
fi


echo "===================================================================================="

#Análisis de Logs
pt "dmesg (últimos 50)"
dmesg | tail -n 50 || true

pt "Logs systemd (últimos 50)"
if command -v journalctl >/dev/null 2>&1; then
  journalctl -n 50 --no-pager || true
fi

pt "Servicios fallidos"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --failed --no-legend || true
fi
