# Script de diagnóstico del sistema — `all.sh`

**Descripción**  
`all.sh` es un script de diagnóstico pensado para entornos Linux (por ejemplo Kali) que recopila información útil del sistema: conectividad, interfaces IP, tabla de enrutado, pruebas de velocidad, particiones, uso de disco, procesos destacados, estado de la red, escaneo con `nmap`, historial de logins y fechas de cambio de contraseña. El script está diseñado para ser ejecutado en una máquina local o VM y obtener un informe rápido del estado del sistema.

> El script espera que uses una función `pt "Título"` para imprimir títulos compactos (puedes incluir la implementación `pt()` en la cabecera del script).

---

## 📌 Características principales

- Ping a `8.8.8.8` y resumen de conectividad.  
- Listado compacto de interfaces (`ip -br a`) y tabla de enrutado.  
- Test de velocidad (si `speedtest` está instalado).  
- Listado de particiones (`lsblk -f`) y uso de disco (`df -Th`).  
- Escaneo de red con `nmap` (objetivo pasado por parámetro; opciones respetadas).  
- Listado de usuarios, historial de login y última fecha de cambio de contraseña (requiere root).  
- Información de procesos: top por memoria y CPU (con línea de comando truncada).  
- Comprobaciones externas: HTTP (curl) y DNS (dig/host).  
- Logs del kernel (`dmesg`) y journal (`journalctl`) con manejo de permisos.  
- Múltiples comprobaciones envueltas para que el script no falle si falta una utilidad (`command -v` + `|| true` o comprobaciones).

---

## ✅ Requisitos

Recomendado (no todos son imprescindibles; el script detecta utilidades faltantes y las omite):

- Bash (≥ 4)  
- `ip` (iproute2)  
- `nmap` (para el escaneo)  
- `curl` (comprobaciones HTTP)  
- `dig` (bind9-dnsutils) o `host` (bind9-host)  
- `speedtest` (opcional, para test de velocidad)  
- `lsblk`, `df`, `ps`, `vmstat`, `dmesg`, `journalctl`, `chage`  
- `awk`, `sed`, `grep`, `date`, `find`, `sort`, `head`

> **Atención:** Para ver la **última fecha de cambio de contraseña** y para leer `/etc/shadow` (o ejecutar `chage`) **se requiere ejecutar el script como root** (por ejemplo `sudo ./all.sh <TARGET>`).

---

## 📦 Instalación / Preparación

1. Copia el script a tu equipo (ej. `/home/kali/cositas/all.sh`) y dale permisos de ejecución:
```bash
chmod +x all.sh

