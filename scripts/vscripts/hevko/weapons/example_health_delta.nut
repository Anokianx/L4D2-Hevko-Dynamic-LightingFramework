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
