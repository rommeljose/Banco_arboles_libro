#!/usr/bin/env bash
# Arma el ESTADO del libro y lo sella en Bitcoin.
#
# NO sella el sha256 del archivo entero: eso cambia con cada línea nueva y
# dejaría obsoleto el sello en cuanto alguien registra un árbol. Sella la
# PUNTA DE LA CADENA y cuántos asientos había.
#
# Así, meses después, cualquiera puede comprobar lo único que importa:
# que el asiento Nº N del libro de hoy sigue teniendo exactamente la huella
# que Bitcoin vio aquel día. Si el libro creció, bien. Si alguien reescribió
# la historia sellada, la punta ya no cuadra y se nota.
set -euo pipefail
cd "$(dirname "$0")"
E=libro/ESTADO.txt
{
  echo "# Banco de Árboles · estado del libro"
  echo "# <archivo> sha256=<del archivo> asientos=<n> punta=<huella del último>"
  for f in libro/*.tsv; do
    n=$(grep -cv -e $'^tipo\t' -e '^$' "$f")   # sin la cabecera
    punta=$(tail -n1 "$f" | cut -f9)
    echo "$f sha256=$(sha256sum "$f" | cut -d' ' -f1) asientos=$n punta=$punta"
  done
  echo "sellado_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$E"
cat "$E"
rm -f "$E.ots"
ots stamp "$E"
mkdir -p libro/sellos
D=$(date -u +%Y-%m-%d)
cp "$E"      "libro/sellos/ESTADO-$D.txt"
cp "$E.ots"  "libro/sellos/ESTADO-$D.txt.ots"
# índice para que la página sepa qué sellos hay sin preguntarle a nadie
ls libro/sellos/ | grep -E '^ESTADO-.*\.txt$' | sort > libro/sellos/INDICE.txt
echo "✓ sellado → libro/sellos/ESTADO-$D.txt.ots"
