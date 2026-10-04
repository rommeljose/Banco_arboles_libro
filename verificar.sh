#!/usr/bin/env bash
# Recalcula la cadena del libro entera. Sin navegador, sin red, sin dependencias
# más allá de coreutils. Si esto da ✓, el libro no fue alterado.
# Uso: ./verificar.sh
set -euo pipefail
cd "$(dirname "$0")"

prev=$(printf '0%.0s' $(seq 64))
n=0

for f in libro/*.tsv; do
  [ -e "$f" ] || continue
  while IFS= read -r cruda || [ -n "$cruda" ]; do
    [ -z "$cruda" ] && continue
    case "$cruda" in tipo"$(printf '\t')"*) continue ;; esac

    # El tabulador es "espacio en blanco" para read y colapsa los campos vacíos.
    # Se cambia por \x01, que no lo es, y así se preservan.
    linea=${cruda//$'\t'/$'\001'}
    IFS=$'\001' read -r tipo id arbol fecha lat lon datos p h <<< "$linea"

    if [ "$p" != "$prev" ]; then
      echo "✗ asiento $id — el eslabón previo no corresponde"
      echo "  esperaba $prev"
      echo "  dice     $p"
      exit 1
    fi

    calc=$(printf '%s|%s|%s|%s|%s|%s|%s|%s' \
            "$prev" "$tipo" "$id" "$arbol" "$fecha" "$lat" "$lon" "$datos" \
           | sha256sum | cut -d' ' -f1)

    if [ "$calc" != "$h" ]; then
      echo "✗ asiento $id — la huella no cuadra"
      echo "  calculada $calc"
      echo "  dice      $h"
      exit 1
    fi
    prev="$h"; n=$((n+1))
  done < "$f"
done

echo "✓ cadena íntegra · $n asiento(s)"
echo "  punta: $prev"
