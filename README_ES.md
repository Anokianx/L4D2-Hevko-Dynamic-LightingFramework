# Hevko

Autor: Anokianx

[English](README.md) | [中文](README_CN.md) | **Español**

Hevko es un framework de iluminación dinámica basado en estados, universal e independiente del arma, diseñado para *Left 4 Dead 2*. Su script principal calcula y genera valores de estado sin depender de modelos de armas o efectos de textura específicos, lo que permite integrarlo directamente en el archivo `.vpk` de cualquier *skin* (apariencia) de arma.

## Características
- **Sistema de salud integrado con 3 umbrales**: Combina automáticamente la salud permanente con la salud temporal (proveniente de pastillas o adrenalina) y considera los estados de «incapacitado» o «colgando de un borde» como una zona de advertencia de salud baja; admite una interpolación fluida.
- **Dos modos de integración**:
  1. `mode = "color"`: No requiere expresiones matemáticas complejas en los archivos VMT. Basta con añadir `"MaterialModify" { "dummy" "0" }` al archivo `.vmt` y definir tres estados de color RGB distintos dentro de la configuración del arma.
  2. `mode = "scalar"`: Genera una variable continua, `$hevko_t` (`0.0` para salud baja, `0.5` para media, `1.0` para alta), que puede utilizarse en los archivos `.vmt` de cada arma para controlar cambios de color personalizados, efectos de pulsación, velocidades de flujo de texturas o velocidades de rotación.

## Estructura de directorios
- `scripts/vscripts/director_base_addon.nut`: Punto de entrada para la inicialización automática.
- `scripts/vscripts/hevko/core.nut`: Motor principal encargado de realizar el seguimiento de múltiples entidades y gestionar la interpolación fluida.
- `scripts/vscripts/hevko/providers/health.nut`: Módulo de estado para supervisar la salud del jugador.
- `scripts/vscripts/hevko/registry.nut`: Registro para cargar los archivos de configuración de las armas.
- `scripts/vscripts/hevko/weapons/`: Archivos de configuración individuales para armas específicas (por ejemplo, `example_color.nut`, `example_scalar.nut`).
- `templates/`: Archivos de plantilla para VMT.

## Cómo realizar la integración en cualquier *mod* de arma
1. Copia el directorio `scripts/` directamente dentro de la carpeta de tu *mod* de arma.
2. Crea un archivo nuevo en `scripts/vscripts/hevko/weapons/nombre_de_tu_script.nut` (puedes elegir cualquier nombre ASCII, como el de tu *mod* o arma), pega una de las dos plantillas siguientes y sustituye el *classname* y las rutas de materiales por los de tu *mod*.
3. Añade la línea `IncludeScript("hevko/weapons/nombre_de_tu_script", getroottable())` en `scripts/vscripts/hevko/registry.nut`. Si tu servidor ya utiliza una colección `director_base_addon.nut` distinta, simplemente añade `IncludeScript("hevko/core", getroottable())` junto con la línea de registro en dicho archivo.
4. En la sección `"Proxies"` de cada archivo `.vmt` listado, añade `"MaterialModify" { "dummy" "0" }` (para `mode = "scalar"`, utiliza `templates/hevko_scalar_unlit.vmt` o `templates/hevko_scalar_vertexlit.vmt`).

### Qué escribir dentro de `nombre_de_tu_script.nut`
Opción A — Modo de color directo (`mode = "color"`, más sencillo, sin fórmulas en el VMT):
```squirrel
if ("Hevko" in getroottable())
{
	::Hevko.RegisterWeapon("weapon_rifle", {
		author = "Anokianx"
		provider = "health"
		mode = "color"
		varName = "$selfillumtint"
		lerpSpeed = 7.5
		highColor = [1.10, 1.05, 1.35]
		midColor = [1.40, 0.95, 0.62]
		lowColor = [1.80, 0.32, 0.48]
		thresholds = {
			highMin = 60.0
			midMin = 30.0
		}
		materials = [
			"models/weapons/v_models/your_mod/weapon_glow"
		]
	})
}
```
Opción B — Modo escalar (`mode = "scalar"`, genera `$hevko_t` `0.0~1.0` para efectos VMT propios):
```squirrel
if ("Hevko" in getroottable())
{
	::Hevko.RegisterWeapon("weapon_rifle_ak47", {
		author = "Anokianx"
		provider = "health"
		mode = "scalar"
		varName = "$hevko_t"
		defaultValue = "1.000"
		lerpSpeed = 7.5
		thresholds = {
			highMin = 60.0
			midMin = 30.0
		}
		materials = [
			"models/weapons/v_models/your_mod/glow_layer"
		]
	})
}
```
Referencia de campos:
- Primer argumento de `RegisterWeapon`: **debe ser el *classname* nativo del arma en L4D2**, no el nombre del *mod*.
- `materials`: lista de rutas `.vmt` relativas a `materials/`, usando barras `/` y **sin** el prefijo `materials/` ni la extensión `.vmt`. También puedes pasar `{ material = "...", varName = "$color" }` para especificar la variable por material y opcionalmente añadir `worldMaterials = [ ... ]` para la tercera persona.
- `varName`: variable del VMT que se va a controlar (`"$selfillumtint"` o `"$color"` en `mode = "color"`; `"$hevko_t"` en `mode = "scalar"`).
- `thresholds`: `highMin` (nivel alto) y `midMin` (nivel medio; por debajo es nivel bajo).
- `lerpSpeed`: velocidad de transición suave (por defecto `7.5`).

## Nombres de clase (*Classnames*) comunes en L4D2
- Francotiradores: `"weapon_sniper_awp"`, `"weapon_sniper_scout"`, `"weapon_sniper_military"`, `"weapon_hunting_rifle"`
- Rifles: `"weapon_rifle"` (M16), `"weapon_rifle_ak47"`, `"weapon_rifle_desert"` (SCAR), `"weapon_rifle_sg552"`, `"weapon_rifle_m60"`
- Subfusiles: `"weapon_smg"`, `"weapon_smg_silenced"`, `"weapon_smg_mp5"`
- Escopetas: `"weapon_pumpshotgun"`, `"weapon_shotgun_chrome"`, `"weapon_autoshotgun"`, `"weapon_shotgun_spas"`
- Pistolas: `"weapon_pistol"`, `"weapon_pistol_magnum"` (Desert Eagle)
- Cuerpo a cuerpo: `"weapon_melee"` (todas) o `"weapon_melee:<nombre_del_script>"` (p. ej., `"weapon_melee:katana"`, `"weapon_melee:fireaxe"`)

## Ampliación con métricas adicionales
Puedes registrar fuentes personalizadas para el cálculo de estados mediante `::Hevko.RegisterProvider("nombre_de_la_metrica", function(player, cfg) { return { value = 0.0~1.0, tier = 0|1|2, raw = valor_numerico } })` y, posteriormente, especificar `provider = "nombre_de_la_metrica"` dentro de la configuración de tu arma.
