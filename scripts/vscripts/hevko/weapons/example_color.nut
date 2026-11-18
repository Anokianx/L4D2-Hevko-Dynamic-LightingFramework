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
