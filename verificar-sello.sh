#!/usr/bin/env bash
# Comprueba un sello contra Bitcoin SIN nodo propio y SIN confiar en nosotros.
#
#   pip install opentimestamps-client
#   ./verificar-sello.sh libro/sellos/ESTADO-2026-10-04.txt
#
# Tres preguntas:
#   1. ¿el recibo es de este archivo?            sha256 contra el .ots
#   2. ¿su ruta de Merkle llega a un bloque real? contra un explorador público
#   3. ¿la historia sellada sigue intacta?        la punta de entonces, hoy
#
# La 3 es la que importa. Que el libro HAYA CRECIDO desde el sello es normal:
# es un libro de solo-añadir. Lo que no puede pasar es que el asiento Nº N de
# hoy tenga una huella distinta de la que Bitcoin vio aquel día.
set -euo pipefail
ARCHIVO="${1:?uso: $0 <archivo-sellado>}"
cd "$(dirname "$0")"
python3 - "$ARCHIVO" <<'PY'
import sys, os, json, hashlib, datetime, urllib.request
from opentimestamps.core.serialize import StreamDeserializationContext
from opentimestamps.core.timestamp import DetachedTimestampFile
from opentimestamps.core.notary import BitcoinBlockHeaderAttestation

a = sys.argv[1]
with open(a + '.ots','rb') as f:
    d = DetachedTimestampFile.deserialize(StreamDeserializationContext(f))

real = hashlib.sha256(open(a,'rb').read()).hexdigest()
ok = real == d.file_digest.hex()
print(f'1 · el recibo es de este archivo ............. {"sí" if ok else "NO"}')
if not ok: sys.exit(1)

bloque = None
for msg, att in d.timestamp.all_attestations():
    if not isinstance(att, BitcoinBlockHeaderAttestation): continue
    calc = msg[::-1].hex()
    h = urllib.request.urlopen(f'https://blockstream.info/api/block-height/{att.height}',
                               timeout=30).read().decode()
    blk = json.load(urllib.request.urlopen(f'https://blockstream.info/api/block/{h}', timeout=30))
    if calc != blk['merkle_root']:
        print(f'2 · la ruta NO lleva al bloque {att.height} — recibo inválido'); sys.exit(1)
    t = datetime.datetime.fromtimestamp(blk['timestamp'], datetime.timezone.utc)
    bloque = (att.height, t)
    print(f'2 · la ruta llega al bloque {att.height} ........ sí')
    print(f'      minado {t.isoformat()}')
if bloque is None:
    print('2 · aún PENDIENTE en Bitcoin — vuelve a correr «ots upgrade» en unas horas')

print('3 · la historia sellada:')
malo = False
for l in open(a, encoding='utf-8'):
    l = l.strip()
    if l.startswith('#') or not l: continue
    if l.startswith('sellado_utc='):
        print(f'      sellado el {l.split("=",1)[1]}'); continue
    campos = l.split()
    # formato antiguo de sha256sum: «<hash>  <archivo>», sin punta ni asientos
    if len(campos) == 2 and len(campos[0]) == 64:
        f, kv = campos[1], {'sha256': campos[0]}
    else:
        f, kv = campos[0], dict(c.split('=',1) for c in campos[1:] if '=' in c)
    if not os.path.exists(f):
        print(f'      {f}: no está acá'); continue
    lineas = [x.rstrip('\n') for x in open(f, encoding='utf-8')
              if x.strip() and not x.startswith('tipo\t')]
    n_sello    = int(kv.get('asientos', 0))
    punta_sello = kv.get('punta')
    if hashlib.sha256(open(f,'rb').read()).hexdigest() == kv['sha256']:
        pass
    if punta_sello is None:
        print(f'      {f}: cambió desde el sello. Este sello es del formato viejo —')
        print(f'        sólo guardaba el sha256 del archivo entero, así que no puede')
        print(f'        distinguir «creció» de «lo reescribieron».')
        continue
    if len(lineas) < n_sello:
        print(f'      {f}: ENCOGIÓ — {len(lineas)} asientos, el sello vio {n_sello} ✗'); malo = True; continue
    # Recalcular la cadena hasta el asiento sellado. La punta sola NO basta:
    # ancla el último eslabón, pero sólo rehacer las huellas propaga ese ancla
    # hacia atrás hasta el primer asiento. Si falta una de las dos, se cuela
    # una reescritura.
    prev, roto = '0'*64, None
    for i in range(n_sello):
        c = lineas[i].split('\t')
        if c[7] != prev: roto = (i, 'el eslabón previo no corresponde'); break
        h = hashlib.sha256('|'.join([prev]+c[:7]).encode()).hexdigest()
        if h != c[8]: roto = (i, 'la huella del asiento no cuadra'); break
        prev = c[8]
    if roto:
        print(f'      {f}: el asiento Nº {roto[0]+1} ({lineas[roto[0]].split(chr(9))[1]}) '
              f'está alterado ✗')
        print(f'        {roto[1]}')
        malo = True
    elif prev == punta_sello:
        est = 'idéntico al sello' if len(lineas) == n_sello else f'creció {n_sello} → {len(lineas)} asientos'
        print(f'      {f}: {est}, historia sellada INTACTA ✓')
    else:
        print(f'      {f}: la cadena cierra, pero en otra punta ✗')
        print(f'        Bitcoin vio {punta_sello} y hoy da {prev}')
        malo = True
sys.exit(1 if malo else 0)
PY
