# Banco de Árboles · el libro

**El libro público de los árboles de Cumaná**, Estado Sucre, Venezuela.

Cada árbol registrado deja aquí un asiento: dónde está, cómo está y la huella de sus
fotos. El libro es de solo-añadir, está encadenado asiento por asiento y se **ancla en la
cadena de bloques de Bitcoin** con [OpenTimestamps](https://opentimestamps.org).
Cualquiera puede comprobarlo sin pedir permiso y sin confiar en nosotros.

- **La página:** https://rommeljose.github.io/Banco_arboles_CA/
- **Verificar una huella o un sello:** https://rommeljose.github.io/Banco_arboles_CA/verificar.html

Una iniciativa asociada a la **Academia de GeoHistoria del Estado Sucre (AGHES)**.
El programa sirve, por el momento, a la capa verde de la ciudad de Cumaná.

> El libro está en **fase de ensayo**. Los primeros asientos son de prueba y tienen
> defectos conocidos. No se borran: en este libro los errores se corrigen añadiendo un
> asiento nuevo, nunca reescribiendo uno viejo.

---

## Qué hay aquí

| | |
|---|---|
| `libro/AAAA-MM.tsv` | los asientos de cada mes, en texto plano separado por tabuladores |
| `libro/INDICE.txt` | la lista de archivos del libro |
| `libro/sellos/` | el estado del libro en cada sello y su recibo `.ots` |
| `libro/sellos/INDICE.txt` | la lista de sellos emitidos |
| `verificar.sh` | recalcula la cadena entera; sólo necesita `sha256sum` |
| `verificar-sello.sh` | comprueba un sello contra Bitcoin, sin nodo propio |
| `sellar.sh` | arma el estado del libro y pide el sello |

## El formato del libro

Una línea por asiento. Se lee con los ojos, con `grep` o con una hoja de cálculo.

```
tipo  id  arbol  fecha_utc  lat  lon  datos  prev  hash
```

| tipo | qué asienta |
|---|---|
| `GEN` | la apertura del libro |
| `OBS` | una observación: un árbol, en un lugar, en una fecha, con sus fotos |
| `DET` | una determinación: qué especie (o género, o familia) se le atribuye a una observación |

En `datos` van pares `clave=valor` separados por `;`. Las claves `f_habito`, `f_corteza`,
`f_hoja` y `f_flor` son el sha256 de cada foto; `fh` es la huella de la observación.

Una determinación **no modifica** la observación: se anota aparte y es revisable. Si más
adelante alguien determina otra cosa, se añade otro `DET` y el anterior queda a la vista.

## Cómo se calcula cada huella

Todo se puede reproducir a mano.

**La huella de una foto** es el sha256 del archivo tal como salió del teléfono del
observador (JPEG, lado mayor de 2048 px, calidad 0,82):

```bash
sha256sum mi-foto.jpg
```

**La huella de una observación** es el sha256 de este registro, separado por `|`:

```
BA1|OBS|<fecha_utc>|<lat>|<lon>|<acc>|<perimetro_cm>|<entorno>|<estado>|<amenazas>|<h_habito>|<h_corteza>|<h_hoja>|<h_flor>
```

`lat` y `lon` llevan exactamente 5 decimales, los campos vacíos quedan vacíos, y las
amenazas van en orden alfabético unidas por coma.

**El eslabón de la cadena** une cada asiento con el anterior:

```
hash = sha256( prev | tipo | id | arbol | fecha_utc | lat | lon | datos )
```

El primer asiento usa 64 ceros como `prev`. La cadena vive dentro del archivo y no en los
commits de git.

## Cómo verificar

**La cadena.** Que ningún asiento fue alterado:

```bash
./verificar.sh
```

**El sello.** Que el libro ya existía, tal cual, en la fecha que Bitcoin atestigua:

```bash
pip install opentimestamps-client
./verificar-sello.sh libro/sellos/ESTADO-2026-10-03a.txt
```

O sin instalar nada, desde la [página de verificar](https://rommeljose.github.io/Banco_arboles_CA/verificar.html),
que hace las dos comprobaciones en el navegador.

Hacen falta las dos. La cadena detecta que se tocó un asiento, pero quien controle este
repositorio podría alterar uno y recalcular todas las huellas siguientes: el libro
quedaría coherente. Lo que no puede cambiar es la punta de la cadena que Bitcoin ya vio.

## El sello

Cada domingo se arma `libro/ESTADO.txt` y se ancla en Bitcoin. No se sella el sha256 del
archivo entero, que cambia con cada asiento nuevo, sino la **punta de la cadena** y
cuántos asientos había:

```
libro/2026-10.tsv sha256=f48011be… asientos=5 punta=9326e36088d61f19…
sellado_utc=2026-10-04T01:24:25Z
```

Así, aunque el libro crezca, cualquiera puede recalcular la cadena hasta el asiento Nº 5
y comprobar que sigue dando la punta sellada. Que el libro haya crecido es normal; que lo
hayan reescrito se nota.

El primer sello está en el **bloque 969 771** de Bitcoin, minado el 3 de octubre de 2026 a
las 22:38:37 UTC. Ese primer sello usa un formato anterior, que sólo guardaba el sha256
del archivo; los siguientes guardan la punta.

Un segundo trabajo corre a diario `ots upgrade`, que trae de los calendarios de
OpenTimestamps el camino hasta el bloque y lo guarda en el recibo.

## Ser testigo

Haz un *fork* de este repositorio. Con eso guardas una copia del libro que nosotros no
controlamos. Para comprobar la página contra tu copia:

```
https://rommeljose.github.io/Banco_arboles_CA/verificar.html?libro=https://raw.githubusercontent.com/<tu-usuario>/Banco_arboles_libro/main/libro/
```

Si tu copia y la oficial dan la misma punta de cadena, nadie tocó nada.

## Quién escribe aquí

Sólo se añaden líneas al final del libro. Nadie que use la página puede escribir en él:
las observaciones pasan por una curaduría y entran en lotes. Los sellos los emite un
robot (`.github/workflows/sello.yml`).

## Créditos

**Academia de GeoHistoria del Estado Sucre (AGHES)**

Responsables:

- Lcdo. MSc. José Fariñas — biólogo, botánico
- Lcdo. Rommel Contreras — físico
- Dr. Kelvis Campos — médico cirujano

---

*Cumaná, octubre de 2026. Fotos bajo CC BY-SA 4.0; código bajo MIT.*
