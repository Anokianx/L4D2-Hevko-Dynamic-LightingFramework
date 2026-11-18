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
