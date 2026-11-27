# Hevko

Author: Anokianx

**English** | [中文](README_CN.md) | [Español](README_ES.md)

Hevko is a universal, weapon-agnostic dynamic state-based lighting framework for *Left 4 Dead 2*. The core script calculates and outputs state values without being coupled to specific weapon models or texture effects, allowing it to be bundled directly into any weapon skin’s `.vpk` file.

## Features
- **Built-in 3-Threshold Health Provider (`health`)**: Automatically combines permanent health with temporary health (from pills/adrenaline) and treats "incapacitated" or "hanging from a ledge" states as a low-health warning zone; supports smooth interpolation.
- **Health Delta Toggle Provider (`health_delta`)**: Combines permanent and temporary health and toggles output `0.0` / `1.0` each time effective health changes by at least `thresholds.step` (default `20.0`) from the last switch point; resets anchor on respawn or map restart.
- **Two Integration Modes**:
  1. `mode = "color"`: Requires no complex VMT mathematical expressions. Simply add `"MaterialModify" { "dummy" "0" }` to your `.vmt` file and define three distinct RGB color states within the weapon’s configuration.
  2. `mode = "scalar"`: Outputs a smooth variable, `$hevko_t` (`0.0` for low, `0.5` for medium, `1.0` for high, or `0.0` / `1.0` toggle with `health_delta`), which can be used within each weapon’s individual `.vmt` to drive color, pulsing rhythms, texture flow rates, or rotation speeds.

## Directory Structure
- `scripts/vscripts/director_base_addon.nut`: Automatic initialization entry point.
- `scripts/vscripts/hevko/core.nut`: Core engine for tracking multiple entities and handling smooth interpolation.
- `scripts/vscripts/hevko/providers/health.nut`: 3-threshold health-detection state provider.
- `scripts/vscripts/hevko/providers/health_delta.nut`: Cumulative HP-delta toggle provider (`step = 20.0` default).
- `scripts/vscripts/hevko/registry.nut`: Registry for loading weapon configuration files.
- `scripts/vscripts/hevko/weapons/`: Individual weapon configuration files (e.g., `example_color.nut`, `example_scalar.nut`, `example_health_delta.nut`).
- `templates/`: VMT template files.

## Quick Integration for Weapon Mods
1. Copy the `scripts/` directory directly into your weapon mod’s folder.
2. Create a new file at `scripts/vscripts/hevko/weapons/your_script_name.nut` (any ASCII filename is fine, e.g., your mod name or weapon name), copy one of the three templates below into it, and change the classname and material paths to match your mod.
3. Add the line `IncludeScript("hevko/weapons/your_script_name", getroottable())` to `scripts/vscripts/hevko/registry.nut`. If your server already uses a different `director_base_addon.nut` collection, simply add `IncludeScript("hevko/core", getroottable())` along with the registration line to that file.
4. In the `"Proxies"` section of each listed `.vmt` file, add `"MaterialModify" { "dummy" "0" }` (for `mode = "scalar"`, use `templates/hevko_scalar_unlit.vmt` or `templates/hevko_scalar_vertexlit.vmt`).

### What to Put Inside `your_script_name.nut`
Option A — Direct 3-Color Mode (`mode = "color"`, easiest, no VMT math needed):
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
Option B — Scalar Mode (`mode = "scalar"`, outputs `$hevko_t` `0.0~1.0` for custom VMT effects):
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
Option C — Health Delta Toggle (`provider = "health_delta"`, toggles `0.0` <-> `1.0` every time effective HP changes by `step`):
```squirrel
if ("Hevko" in getroottable())
{
	::Hevko.RegisterWeapon("weapon_rifle", {
		author = "Anokianx"
		provider = "health_delta"
		mode = "scalar"
		varName = "$hevko_t"
		defaultValue = "0.000"
		lerpSpeed = 4.2
		thresholds = {
			step = 20.0
		}
		materials = [
			"models/weapons/v_models/your_mod/glow_layer"
		]
	})
}
```
Field reference:
- First argument of `RegisterWeapon`: **must be the built-in L4D2 weapon classname** (not your mod name).
- `materials`: list of `.vmt` paths relative to `materials/`, using `/` forward slashes, **without** leading `materials/` and **without** `.vmt` extension. You can also pass `{ material = "...", varName = "$color" }` to override `varName` per material, and optionally add `worldMaterials = [ ... ]` to limit third-person materials.
- `varName`: target VMT variable to drive (e.g., `"$selfillumtint"` or `"$color"` for `mode = "color"`, `"$hevko_t"` for `mode = "scalar"`).
- `thresholds`: for `health`, `highMin` (>= High tier) and `midMin` (>= Mid tier, below is Low tier); for `health_delta`, `step` (minimum HP change in either direction required to flip `0.0 <-> 1.0`, default `20.0`).
- `lerpSpeed`: transition smoothness speed (higher = faster, default `7.5`).

## Common L4D2 Weapon Classnames
- Snipers: `"weapon_sniper_awp"`, `"weapon_sniper_scout"`, `"weapon_sniper_military"`, `"weapon_hunting_rifle"`
- Rifles: `"weapon_rifle"` (M16), `"weapon_rifle_ak47"`, `"weapon_rifle_desert"` (SCAR), `"weapon_rifle_sg552"`, `"weapon_rifle_m60"`
- SMGs: `"weapon_smg"`, `"weapon_smg_silenced"`, `"weapon_smg_mp5"`
- Shotguns: `"weapon_pumpshotgun"`, `"weapon_shotgun_chrome"`, `"weapon_autoshotgun"`, `"weapon_shotgun_spas"`
- Pistols: `"weapon_pistol"`, `"weapon_pistol_magnum"` (Desert Eagle)
- Melee: `"weapon_melee"` (all melee weapons) or `"weapon_melee:<script_name>"` (e.g., `"weapon_melee:katana"`, `"weapon_melee:fireaxe"`)

## Adding Custom Metrics
You can register any custom state calculation source using `::Hevko.RegisterProvider("metric_name", function(player, cfg) { return { value = 0.0~1.0, tier = 0|1|2, raw = numeric_value } })`, and then specify `provider = "metric_name"` within your weapon configuration.
